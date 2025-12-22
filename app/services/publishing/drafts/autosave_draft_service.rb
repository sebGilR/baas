# frozen_string_literal: true

module Publishing
  module Drafts
    class AutosaveDraftService < ApplicationService
      def initialize(draft:, user:, attributes:)
        @draft = draft
        @user = user
        @attributes = attributes.to_h.symbolize_keys
      end

      def call
        return failure(errors: "Draft is required", code: Codes::VALIDATION_FAILED) unless draft
        return failure(errors: "User is required", code: Codes::VALIDATION_FAILED) unless user
        return failure(errors: "Content is required", code: Codes::VALIDATION_FAILED) unless content_attributes_present?

        draft.autosave!(**autosave_attributes)

        success(draft: draft)
      rescue ActiveRecord::RecordInvalid => e
        failure(errors: e.record.errors.full_messages, code: Codes::VALIDATION_FAILED)
      end

      private

      attr_reader :draft, :user, :attributes

      def editable_attributes
        attributes.slice(:title, :content, :content_json, :content_html, :content_text)
      end

      def autosave_attributes
        editable_attributes.compact
      end

      def content_attributes_present?
        editable_attributes.except(:title).values.any?(&:present?)
      end
    end
  end
end
