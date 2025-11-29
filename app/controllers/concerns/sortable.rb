# frozen_string_literal: true

# Provides sorting helpers for API controllers
# Follows JSON:API sorting conventions with sort=-field,field
# Prefix with - for descending order
#
# @example
#   GET /api/v1/posts?sort=-published_at,title
#
#   class PostsController < ApplicationController
#     include Sortable
#
#     def index
#       posts = apply_sorting(Post.all)
#       render json: serialize(posts)
#     end
#
#     private
#
#     def allowed_sort_fields
#       [:title, :published_at, :created_at, :updated_at]
#     end
#   end
#
module Sortable
  extend ActiveSupport::Concern

  private

  # Parse sort parameter into array of order hashes
  # @return [Array<Hash>] Array of { field: :direction } hashes
  def sort_params
    return default_sort if params[:sort].blank?

    params[:sort].split(",").filter_map do |field|
      parse_sort_field(field.strip)
    end.presence || default_sort
  end

  # Parse a single sort field
  # @param field [String] Field name, optionally prefixed with -
  # @return [Hash, nil]
  def parse_sort_field(field)
    if field.start_with?("-")
      field_name = field[1..].to_sym
      return if allowed_sort_fields.exclude?(field_name)

      { field_name => :desc }
    else
      field_name = field.to_sym
      return if allowed_sort_fields.exclude?(field_name)

      { field_name => :asc }
    end
  end

  # Override in controller to specify allowed sort fields
  # @return [Array<Symbol>]
  def allowed_sort_fields
    [:created_at, :updated_at]
  end

  # Default sort order when no sort param provided
  # Override in controller for different defaults
  # @return [Array<Hash>]
  def default_sort
    [{ created_at: :desc }]
  end

  # Apply sorting to a scope
  # @param scope [ActiveRecord::Relation]
  # @return [ActiveRecord::Relation]
  def apply_sorting(scope)
    sort_params.reduce(scope) do |s, order|
      s.order(order)
    end
  end
end
