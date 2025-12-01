# frozen_string_literal: true

module Publishing
  module Blogs
    class DeleteBlogService < ApplicationService
      def initialize(blog:, user:)
        @blog = blog
        @user = user
      end

      def call
        return failure(errors: "Blog is required", code: Codes::VALIDATION_FAILED) unless blog
        return failure(errors: "User is required", code: Codes::VALIDATION_FAILED) unless user

        # Soft delete by marking as deleted
        unless blog.update(status: :deleted)
          return failure(errors: blog.errors.full_messages, code: Codes::VALIDATION_FAILED)
        end

        success(blog: blog)
      end

      private

      attr_reader :blog, :user
    end
  end
end
