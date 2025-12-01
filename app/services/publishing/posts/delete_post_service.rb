# frozen_string_literal: true

module Publishing
  module Posts
    class DeletePostService < ApplicationService
      def initialize(post:, user:)
        @post = post
        @user = user
      end

      def call
        return failure(errors: "Post is required", code: Codes::VALIDATION_FAILED) unless post
        return failure(errors: "User is required", code: Codes::VALIDATION_FAILED) unless user

        # Soft delete by archiving
        unless post.update(status: :archived)
          return failure(errors: post.errors.full_messages, code: Codes::VALIDATION_FAILED)
        end

        success(post: post)
      end

      private

      attr_reader :post, :user
    end
  end
end
