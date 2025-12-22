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

          unless post.update(permitted_attributes)
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
        [:content, :content_json, :content_html, :content_text].any? do |attribute|
          next unless attributes.key?(attribute)

          attributes[attribute] != post.public_send(attribute)
        end
      end
    end
  end
end
