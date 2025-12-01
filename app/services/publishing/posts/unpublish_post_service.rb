# frozen_string_literal: true

module Publishing
  module Posts
    class UnpublishPostService < ApplicationService
      def initialize(post:, user:)
        @post = post
        @user = user
      end

      def call
        return failure(errors: "Post is required", code: Codes::VALIDATION_FAILED) unless post
        return failure(errors: "User is required", code: Codes::VALIDATION_FAILED) unless user
        return failure(errors: "Post is not published", code: Codes::VALIDATION_FAILED) unless post.status_published?

        unless post.unpublish!
          return failure(errors: post.errors.full_messages, code: Codes::VALIDATION_FAILED)
        end

        success(post: post)
      end

      private

      attr_reader :post, :user
    end
  end
end
