# frozen_string_literal: true

module Api
  module V1
    class DraftsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_draft, only: [:show, :update, :destroy, :autosave, :convert_to_post]
      before_action :set_blog, only: [:create]

      # GET /api/v1/drafts
      def index
        @drafts = policy_scope(Draft, policy_scope_class: Publishing::DraftPolicy::Scope)
          .includes(:blog, :author, :tags)
          .ordered

        # Optional filters
        @drafts = @drafts.by_blog(params[:blog_id]) if params[:blog_id].present?
        @drafts = @drafts.by_author(current_user.id) if params[:mine] == "true"

        @drafts = @drafts.page(params[:page]).per(params[:per_page] || 20)

        render_jsonapi(
          @drafts,
          meta: pagination_meta(@drafts),
          include: params[:include],
        )
      end

      # GET /api/v1/drafts/:id
      def show
        render_jsonapi(@draft, include: params[:include])
      end

      # POST /api/v1/drafts
      def create
        authorize(Draft, policy_class: Publishing::DraftPolicy)

        result = Publishing::Drafts::CreateDraftService.call(
          account: current_account,
          blog: @blog,
          user: current_user,
          attributes: draft_params,
        )

        if result.success?
          render_jsonapi(result.draft, status: :created, include: params[:include])
        else
          render_error(:unprocessable_entity, detail: result.errors)
        end
      end

      # PATCH/PUT /api/v1/drafts/:id
      def update
        result = Publishing::Drafts::UpdateDraftService.call(
          draft: @draft,
          user: current_user,
          attributes: draft_params,
        )

        if result.success?
          render_jsonapi(result.draft, include: params[:include])
        else
          render_error(:unprocessable_entity, detail: result.errors)
        end
      end

      # DELETE /api/v1/drafts/:id
      def destroy
        result = Publishing::Drafts::DeleteDraftService.call(
          draft: @draft,
          user: current_user,
        )

        if result.success?
          head(:no_content)
        else
          render_error(:unprocessable_entity, detail: result.errors)
        end
      end

      # POST /api/v1/drafts/:id/autosave
      def autosave
        authorize(@draft, :autosave?, policy_class: Publishing::DraftPolicy)

        result = Publishing::Drafts::AutosaveDraftService.call(
          draft: @draft,
          user: current_user,
          content: autosave_params[:content],
          title: autosave_params[:title],
        )

        if result.success?
          render_jsonapi(result.draft)
        else
          render_error(:unprocessable_entity, detail: result.errors)
        end
      end

      # POST /api/v1/drafts/:id/convert_to_post
      def convert_to_post
        authorize(@draft, :convert_to_post?, policy_class: Publishing::DraftPolicy)

        result = Publishing::Drafts::ConvertToPostService.call(
          draft: @draft,
          user: current_user,
        )

        if result.success?
          render_jsonapi(result.post, status: :created)
        else
          render_error(:unprocessable_entity, detail: result.errors)
        end
      end

      private

      def set_draft
        @draft = Draft.find_by!(public_id: params[:id])
        authorize(@draft, policy_class: Publishing::DraftPolicy)
      end

      def set_blog
        blog_id = draft_params[:blog_id] || params.dig(:data, :relationships, :blog, :data, :id)
        @blog = Blog.find_by!(public_id: blog_id) if blog_id.present?
      end

      def draft_params
        params.require(:data).require(:attributes).permit(
          :title,
          :content,
          :blog_id,
          :post_id,
          metadata: {},
        )
      end

      def autosave_params
        params.require(:data).require(:attributes).permit(:title, :content)
      end
    end
  end
end
