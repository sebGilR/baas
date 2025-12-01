# frozen_string_literal: true

module Publishing
  module Drafts
    class CreateDraftService < ApplicationService
      def initialize(account:, blog:, user:, attributes:)
        @account = account
        @blog = blog
        @user = user
        @attributes = attributes.to_h.symbolize_keys
      end

      def call
        return failure(errors: "Account is required", code: Codes::VALIDATION_FAILED) unless account
        return failure(errors: "Blog is required", code: Codes::VALIDATION_FAILED) unless blog
        return failure(errors: "User is required", code: Codes::VALIDATION_FAILED) unless user

        draft = build_draft
        return failure(errors: draft.errors.full_messages, code: Codes::VALIDATION_FAILED) unless draft.save

        success(draft: draft)
      end

      private

      attr_reader :account, :blog, :user, :attributes

      def build_draft
        blog.drafts.build(
          account: account,
          author: user,
          title: attributes[:title],
          content: attributes[:content],
          post_id: attributes[:post_id],
          metadata: attributes[:metadata] || {},
          autosaved_at: Time.current
        )
      end
    end
  end
end
