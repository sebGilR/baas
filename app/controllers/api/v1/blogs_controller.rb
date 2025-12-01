# frozen_string_literal: true

module Api
  module V1
    class BlogsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_blog, only: [:show, :update, :destroy]

      # GET /api/v1/blogs
      def index
        @blogs = policy_scope(Blog, policy_scope_class: Publishing::BlogPolicy::Scope)
                 .active
                 .ordered

        @blogs = @blogs.page(params[:page]).per(params[:per_page] || 20)

        render jsonapi: @blogs,
               meta: pagination_meta(@blogs),
               include: params[:include]
      end

      # GET /api/v1/blogs/:id
      def show
        render jsonapi: @blog, include: params[:include]
      end

      # POST /api/v1/blogs
      def create
        authorize Blog, policy_class: Publishing::BlogPolicy

        result = Publishing::Blogs::CreateBlogService.call(
          account: current_account,
          user: current_user,
          attributes: blog_params
        )

        if result.success?
          render jsonapi: result.blog, status: :created
        else
          render_error(:unprocessable_entity, detail: result.errors)
        end
      end

      # PATCH/PUT /api/v1/blogs/:id
      def update
        result = Publishing::Blogs::UpdateBlogService.call(
          blog: @blog,
          user: current_user,
          attributes: blog_params
        )

        if result.success?
          render jsonapi: result.blog
        else
          render_error(:unprocessable_entity, detail: result.errors)
        end
      end

      # DELETE /api/v1/blogs/:id
      def destroy
        result = Publishing::Blogs::DeleteBlogService.call(
          blog: @blog,
          user: current_user
        )

        if result.success?
          head :no_content
        else
          render_error(:unprocessable_entity, detail: result.errors)
        end
      end

      private

      def set_blog
        @blog = Blog.find_by!(public_id: params[:id])
        authorize @blog, policy_class: Publishing::BlogPolicy
      end

      def blog_params
        params.require(:data).require(:attributes).permit(
          :name, :slug, :description, :status,
          settings: {}
        )
      end
    end
  end
end
