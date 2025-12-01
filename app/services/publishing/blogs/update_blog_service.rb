# frozen_string_literal: true

module Publishing
  module Blogs
    class UpdateBlogService < ApplicationService
      def initialize(blog:, user:, attributes:)
        @blog = blog
        @user = user
        @attributes = attributes.to_h.symbolize_keys
      end

      def call
        return failure(errors: "Blog is required", code: Codes::VALIDATION_FAILED) unless blog
        return failure(errors: "User is required", code: Codes::VALIDATION_FAILED) unless user

        unless blog.update(permitted_attributes)
          return failure(errors: blog.errors.full_messages, code: Codes::VALIDATION_FAILED)
        end

        success(blog: blog)
      end

      private

      attr_reader :blog, :user, :attributes

      def permitted_attributes
        attributes.slice(:name, :slug, :description, :settings, :status)
      end
    end
  end
end
