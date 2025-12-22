# frozen_string_literal: true

module Api
  module V1
    class PostsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_post, only: [:show, :update, :destroy, :publish, :unpublish]
      before_action :set_blog, only: [:create]

      # GET /api/v1/posts
      def index
        @posts = policy_scope(Post, policy_scope_class: Publishing::PostPolicy::Scope)
          .includes(:blog, :author, :category, :tags)
          .ordered

        # Optional filters
        @posts = @posts.by_blog(params[:blog_id]) if params[:blog_id].present?
        @posts = @posts.where(status: params[:status]) if params[:status].present?
        @posts = @posts.featured if params[:featured] == "true"

        @posts = @posts.page(params[:page]).per(params[:per_page] || 20)

        render_jsonapi(
          @posts,
          meta: pagination_meta(@posts),
          include: params[:include],
        )
      end

      # GET /api/v1/posts/:id
      def show
        render_jsonapi(@post, include: params[:include])
      end

      # POST /api/v1/posts
      def create
        authorize(Post, policy_class: Publishing::PostPolicy)

        result = Publishing::Posts::CreatePostService.call(
          account: current_account,
          blog: @blog,
          user: current_user,
          attributes: post_params,
        )

        if result.success?
          render_jsonapi(result.post, status: :created, include: params[:include])
        else
          render_error(:unprocessable_entity, detail: result.errors)
        end
      end

      # PATCH/PUT /api/v1/posts/:id
      def update
        result = Publishing::Posts::UpdatePostService.call(
          post: @post,
          user: current_user,
          attributes: post_params,
        )

        if result.success?
          render_jsonapi(result.post, include: params[:include])
        else
          render_error(:unprocessable_entity, detail: result.errors)
        end
      end

      # DELETE /api/v1/posts/:id
      def destroy
        result = Publishing::Posts::DeletePostService.call(
          post: @post,
          user: current_user,
        )

        if result.success?
          head(:no_content)
        else
          render_error(:unprocessable_entity, detail: result.errors)
        end
      end

      # POST /api/v1/posts/:id/publish
      def publish
        authorize(@post, :publish?, policy_class: Publishing::PostPolicy)

        result = Publishing::Posts::PublishPostService.call(
          post: @post,
          user: current_user,
        )

        if result.success?
          render_jsonapi(result.post)
        else
          render_error(:unprocessable_entity, detail: result.errors)
        end
      end

      # POST /api/v1/posts/:id/unpublish
      def unpublish
        authorize(@post, :unpublish?, policy_class: Publishing::PostPolicy)

        result = Publishing::Posts::UnpublishPostService.call(
          post: @post,
          user: current_user,
        )

        if result.success?
          render_jsonapi(result.post)
        else
          render_error(:unprocessable_entity, detail: result.errors)
        end
      end

      private

      def set_post
        @post = Post.find_by!(public_id: params[:id])
        authorize(@post, policy_class: Publishing::PostPolicy)
      end

      def set_blog
        blog_id = post_params[:blog_id] || params.dig(:data, :relationships, :blog, :data, :id)
        @blog = Blog.find_by!(public_id: blog_id) if blog_id.present?
      end

      def post_params
        params.require(:data).require(:attributes).permit(
          :title,
          :slug,
          :content,
          :content_html,
          :content_text,
          :excerpt,
          :status,
          :seo_title,
          :seo_description,
          :featured,
          :blog_id,
          :category_id,
          tag_ids: [],
          content_json: {},
          metadata: {},
        )
      end
    end
  end
end
