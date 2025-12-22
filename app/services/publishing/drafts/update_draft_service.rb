# frozen_string_literal: true

module Publishing
  module Drafts
    class UpdateDraftService < ApplicationService
      def initialize(draft:, user:, attributes:)
        @draft = draft
        @user = user
        @attributes = attributes.to_h.symbolize_keys
      end

      def call
        return failure(errors: "Draft is required", code: Codes::VALIDATION_FAILED) unless draft
        return failure(errors: "User is required", code: Codes::VALIDATION_FAILED) unless user

        unless draft.update(permitted_attributes.merge(autosaved_at: Time.current))
          return failure(errors: draft.errors.full_messages, code: Codes::VALIDATION_FAILED)
        end

        success(draft: draft)
      end

      private

      attr_reader :draft, :user, :attributes

      def permitted_attributes
        attributes.slice(:title, :content, :content_json, :content_html, :content_text, :metadata).compact
      end
    end
  end
end
