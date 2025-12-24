# frozen_string_literal: true

module Publishing
  module Posts
    class PublishPostService < ApplicationService
      def initialize(post:, user:)
        @post = post
        @user = user
      end

      def call
        return failure(errors: "Post is required", code: Codes::VALIDATION_FAILED) unless post
        return failure(errors: "User is required", code: Codes::VALIDATION_FAILED) unless user
        return failure(errors: "Post cannot be published without content", code: Codes::VALIDATION_FAILED) unless post.can_publish?

        # Create a revision before publishing
        post.create_revision!(user)
        RichContent::ArtifactPipeline.apply(post)

        unless post.publish!
          return failure(errors: post.errors.full_messages, code: Codes::VALIDATION_FAILED)
        end

        success(post: post)
      end

      private

      attr_reader :post, :user
    end
  end
end
