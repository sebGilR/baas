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

        draft.assign_attributes(permitted_attributes.merge(autosaved_at: Time.current))
        RichContent::ArtifactPipeline.apply(draft, pipeline_sources)

        unless draft.save
          return failure(errors: draft.errors.full_messages, code: Codes::VALIDATION_FAILED)
        end

        success(draft: draft)
      end

      private

      attr_reader :draft, :user, :attributes

      def permitted_attributes
        attributes.slice(:title, :content, :content_json, :content_html, :content_text, :metadata).compact
      end

      def pipeline_sources
        {
          content_json: attributes[:content_json],
          content_html: attributes[:content_html],
          content_text: attributes[:content_text],
          legacy_content: attributes[:content],
        }.compact
      end
    end
  end
end
