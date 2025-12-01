# frozen_string_literal: true

module Publishing
  module Drafts
    class DeleteDraftService < ApplicationService
      def initialize(draft:, user:)
        @draft = draft
        @user = user
      end

      def call
        return failure(errors: "Draft is required", code: Codes::VALIDATION_FAILED) unless draft
        return failure(errors: "User is required", code: Codes::VALIDATION_FAILED) unless user

        draft.destroy!

        success(draft: draft)
      rescue ActiveRecord::RecordNotDestroyed => e
        failure(errors: e.record.errors.full_messages, code: Codes::VALIDATION_FAILED)
      end

      private

      attr_reader :draft, :user
    end
  end
end
