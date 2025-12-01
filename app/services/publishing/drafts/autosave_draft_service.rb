# frozen_string_literal: true

module Publishing
  module Drafts
    class AutosaveDraftService < ApplicationService
      def initialize(draft:, user:, content:, title: nil)
        @draft = draft
        @user = user
        @content = content
        @title = title
      end

      def call
        return failure(errors: "Draft is required", code: Codes::VALIDATION_FAILED) unless draft
        return failure(errors: "User is required", code: Codes::VALIDATION_FAILED) unless user
        return failure(errors: "Content is required", code: Codes::VALIDATION_FAILED) if content.nil?

        draft.autosave!(content: content, title: title)

        success(draft: draft)
      rescue ActiveRecord::RecordInvalid => e
        failure(errors: e.record.errors.full_messages, code: Codes::VALIDATION_FAILED)
      end

      private

      attr_reader :draft, :user, :content, :title
    end
  end
end
