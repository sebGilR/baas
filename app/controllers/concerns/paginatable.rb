# frozen_string_literal: true

# Provides pagination helpers for API controllers
# Follows JSON:API pagination conventions with page[number] and page[size]
#
# @example
#   class PostsController < ApplicationController
#     include Paginatable
#
#     def index
#       posts = paginate(Post.all)
#       render json: {
#         data: serialize(posts),
#         meta: pagination_meta(posts)
#       }
#     end
#   end
#
module Paginatable
  extend ActiveSupport::Concern

  DEFAULT_PAGE_SIZE = 20
  MAX_PAGE_SIZE = 100

  private

  # Extract page number from params (1-indexed)
  # @return [Integer]
  def page_number
    params.dig(:page, :number)&.to_i || 1
  end

  # Extract page size from params, capped at MAX_PAGE_SIZE
  # @return [Integer]
  def page_size
    size = params.dig(:page, :size)&.to_i || DEFAULT_PAGE_SIZE
    [size, MAX_PAGE_SIZE].min
  end

  # Paginate a scope using Kaminari
  # @param scope [ActiveRecord::Relation]
  # @return [ActiveRecord::Relation]
  def paginate(scope)
    scope.page(page_number).per(page_size)
  end

  # Generate pagination metadata for response
  # @param collection [ActiveRecord::Relation] Paginated collection
  # @return [Hash]
  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      page_size: collection.limit_value,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
    }
  end

  # Generate pagination links for response
  # @param collection [ActiveRecord::Relation] Paginated collection
  # @param base_url [String] Base URL for links
  # @return [Hash]
  def pagination_links(collection, base_url: request.path)
    links = {
      self: page_link(base_url, collection.current_page),
      first: page_link(base_url, 1),
      last: page_link(base_url, collection.total_pages),
    }

    links[:prev] = page_link(base_url, collection.prev_page) if collection.prev_page
    links[:next] = page_link(base_url, collection.next_page) if collection.next_page

    links
  end

  # Generate a pagination link
  # @param base_url [String]
  # @param page [Integer]
  # @return [String]
  def page_link(base_url, page)
    "#{base_url}?page[number]=#{page}&page[size]=#{page_size}"
  end
end
