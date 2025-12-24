# frozen_string_literal: true

module Publishing
  module Posts
    class UpdatePostService < ApplicationService
      def initialize(post:, user:, attributes:)
        @post = post
        @user = user
        @attributes = attributes.to_h.symbolize_keys
      end

      def call
        return failure(errors: "Post is required", code: Codes::VALIDATION_FAILED) unless post
        return failure(errors: "User is required", code: Codes::VALIDATION_FAILED) unless user

        ActiveRecord::Base.transaction do
          # Create a revision before updating (for content versioning)
          create_revision_if_content_changed

          post.assign_attributes(permitted_attributes)
          RichContent::ArtifactPipeline.apply(post, pipeline_sources) if content_attributes_present?

          unless post.save
            raise ActiveRecord::Rollback
          end

          # Update tags if provided
          update_tags if attributes.key?(:tag_ids)
        end

        return failure(errors: post.errors.full_messages, code: Codes::VALIDATION_FAILED) if post.errors.any?

        success(post: post)
      end

      private

      attr_reader :post, :user, :attributes

      def permitted_attributes
        attributes.slice(
          :title, :slug, :content, :content_json, :content_html, :content_text,
          :excerpt, :status,
          :seo_title, :seo_description, :featured, :category_id, :metadata
        ).compact
      end

      def create_revision_if_content_changed
        return unless content_attributes_changed?

        post.create_revision!(user)
      end

      def update_tags
        # Remove existing tags
        post.taggings.destroy_all

        # Add new tags
        tag_ids = Array(attributes[:tag_ids])
        return if tag_ids.empty?

        tags = Tag.where(account: post.account, public_id: tag_ids)
        tags.each do |tag|
          post.taggings.create!(account: post.account, tag: tag)
        end
      end

      def content_attributes_changed?
        content_attribute_keys.any? do |attribute|
          next unless attributes.key?(attribute)

          attributes[attribute] != post.public_send(attribute)
        end
      end

      def content_attributes_present?
        content_attribute_keys.any? { |attribute| attributes.key?(attribute) }
      end

      def content_attribute_keys
        [:content, :content_json, :content_html, :content_text]
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
