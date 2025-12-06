# frozen_string_literal: true

module Api
  module V1
    class TagsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_tag, only: [:show, :update, :destroy]

      # GET /api/v1/tags
      def index
        @tags = policy_scope(Tag, policy_scope_class: Publishing::TagPolicy::Scope)
          .ordered

        @tags = @tags.popular if params[:sort] == "popular"
        @tags = @tags.page(params[:page]).per(params[:per_page] || 50)

        render_jsonapi(
          @tags,
          meta: pagination_meta(@tags),
          include: params[:include],
        )
      end

      # GET /api/v1/tags/:id
      def show
        render_jsonapi(@tag, include: params[:include])
      end

      # POST /api/v1/tags
      def create
        authorize(Tag, policy_class: Publishing::TagPolicy)

        @tag = current_account.tags.build(tag_params)

        if @tag.save
          render_jsonapi(@tag, status: :created)
        else
          render_error(:unprocessable_entity, detail: @tag.errors.full_messages)
        end
      end

      # PATCH/PUT /api/v1/tags/:id
      def update
        if @tag.update(tag_params)
          render_jsonapi(@tag)
        else
          render_error(:unprocessable_entity, detail: @tag.errors.full_messages)
        end
      end

      # DELETE /api/v1/tags/:id
      def destroy
        @tag.destroy!
        head(:no_content)
      rescue ActiveRecord::RecordNotDestroyed => e
        render_error(:unprocessable_entity, detail: e.record.errors.full_messages)
      end

      private

      def set_tag
        @tag = Tag.find_by!(public_id: params[:id])
        authorize(@tag, policy_class: Publishing::TagPolicy)
      end

      def tag_params
        params.require(:data).require(:attributes).permit(:name, :slug, :color)
      end
    end
  end
end
