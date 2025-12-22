# frozen_string_literal: true

module Publishing
  module Drafts
    class ConvertToPostService < ApplicationService
      def initialize(draft:, user:)
        @draft = draft
        @user = user
      end

      def call
        return failure(errors: "Draft is required", code: Codes::VALIDATION_FAILED) unless draft
        return failure(errors: "User is required", code: Codes::VALIDATION_FAILED) unless user
        return failure(errors: "Draft must have a title", code: Codes::VALIDATION_FAILED) if draft.title.blank?
        return failure(errors: "Draft must have content", code: Codes::VALIDATION_FAILED) unless draft.rich_content_present?

        post = draft.convert_to_post!

        if post
          success(post: post)
        else
          failure(errors: "Failed to convert draft to post", code: Codes::VALIDATION_FAILED)
        end
      rescue ActiveRecord::RecordInvalid => e
        failure(errors: e.record.errors.full_messages, code: Codes::VALIDATION_FAILED)
      end

      private

      attr_reader :draft, :user
    end
  end
end
