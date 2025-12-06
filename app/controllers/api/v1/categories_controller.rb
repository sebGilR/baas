# frozen_string_literal: true

module Api
  module V1
    class CategoriesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_category, only: [:show, :update, :destroy]

      # GET /api/v1/categories
      def index
        @categories = policy_scope(Category, policy_scope_class: Publishing::CategoryPolicy::Scope)
          .ordered

        # Filter by root categories only if requested
        @categories = @categories.roots if params[:roots] == "true"

        @categories = @categories.page(params[:page]).per(params[:per_page] || 50)

        render_jsonapi(
          @categories,
          meta: pagination_meta(@categories),
          include: params[:include],
        )
      end

      # GET /api/v1/categories/:id
      def show
        render_jsonapi(@category, include: params[:include])
      end

      # POST /api/v1/categories
      def create
        authorize(Category, policy_class: Publishing::CategoryPolicy)

        @category = current_account.categories.build(category_params)

        # Handle parent relationship if provided
        if params.dig(:data, :relationships, :parent, :data, :id).present?
          parent = Category.find_by!(public_id: params[:data][:relationships][:parent][:data][:id])
          @category.parent = parent
        end

        if @category.save
          render_jsonapi(@category, status: :created, include: params[:include])
        else
          render_error(:unprocessable_entity, detail: @category.errors.full_messages)
        end
      end

      # PATCH/PUT /api/v1/categories/:id
      def update
        # Handle parent relationship if provided
        if params.dig(:data, :relationships, :parent, :data).present?
          parent_id = params[:data][:relationships][:parent][:data][:id]
          if parent_id.present?
            parent = Category.find_by!(public_id: parent_id)
            @category.parent = parent
          else
            @category.parent = nil
          end
        end

        if @category.update(category_params)
          render_jsonapi(@category, include: params[:include])
        else
          render_error(:unprocessable_entity, detail: @category.errors.full_messages)
        end
      end

      # DELETE /api/v1/categories/:id
      def destroy
        @category.destroy!
        head(:no_content)
      rescue ActiveRecord::RecordNotDestroyed => e
        render_error(:unprocessable_entity, detail: e.record.errors.full_messages)
      end

      private

      def set_category
        @category = Category.find_by!(public_id: params[:id])
        authorize(@category, policy_class: Publishing::CategoryPolicy)
      end

      def category_params
        params.require(:data).require(:attributes).permit(:name, :slug, :description, :position)
      end
    end
  end
end
