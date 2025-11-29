# frozen_string_literal: true

# Provides filtering helpers for API controllers
# Follows JSON:API filtering conventions with filter[field]=value
#
# @example
#   class PostsController < ApplicationController
#     include Filterable
#
#     def index
#       posts = apply_filters(Post.all)
#       render json: serialize(posts)
#     end
#
#     private
#
#     def allowed_filters
#       [:status, :author_id, :blog_id]
#     end
#   end
#
module Filterable
  extend ActiveSupport::Concern

  private

  # Extract filter params from request
  # Only returns filters that are in allowed_filters
  # @return [ActionController::Parameters]
  def filter_params
    return {} if params[:filter].blank?

    params.expect(filter: [allowed_filters])
  end

  # Override in controller to specify allowed filter fields
  # @return [Array<Symbol>]
  def allowed_filters
    []
  end

  # Apply filters to a scope
  # @param scope [ActiveRecord::Relation]
  # @return [ActiveRecord::Relation]
  def apply_filters(scope)
    filter_params.each do |key, value|
      next if value.blank?

      scope = apply_filter(scope, key, value)
    end
    scope
  end

  # Apply a single filter to the scope
  # Override for custom filter logic
  # @param scope [ActiveRecord::Relation]
  # @param key [String] Filter key
  # @param value [String] Filter value
  # @return [ActiveRecord::Relation]
  def apply_filter(scope, key, value)
    # Handle comma-separated values as array (e.g., filter[status]=draft,published)
    if value.include?(",")
      scope.where(key => value.split(",").map(&:strip))
    else
      scope.where(key => value)
    end
  end
end
