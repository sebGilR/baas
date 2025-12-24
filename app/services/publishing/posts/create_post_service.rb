# frozen_string_literal: true

module Publishing
  module Posts
    class CreatePostService < ApplicationService
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

        post = build_post
        RichContent::ArtifactPipeline.apply(post, pipeline_sources)
        return failure(errors: post.errors.full_messages, code: Codes::VALIDATION_FAILED) unless post.save

        # Handle tags if provided
        assign_tags(post) if attributes[:tag_ids].present?

        success(post: post)
      end

      private

      attr_reader :account, :blog, :user, :attributes

      def build_post
        blog.posts.build(
          account: account,
          author: user,
          title: attributes[:title],
          slug: attributes[:slug],
          excerpt: attributes[:excerpt],
          status: attributes[:status] || :draft,
          seo_title: attributes[:seo_title],
          seo_description: attributes[:seo_description],
          featured: attributes[:featured] || false,
          category_id: attributes[:category_id],
          metadata: attributes[:metadata] || {},
        )
      end

      def assign_tags(post)
        tag_ids = Array(attributes[:tag_ids])
        tags = Tag.where(account: account, public_id: tag_ids)

        tags.each do |tag|
          post.taggings.create!(account: account, tag: tag)
        end
      end

      def pipeline_sources
        {
          content_json: attributes[:content_json],
          content_html: attributes[:content_html],
          content_text: attributes[:content_text],
          legacy_content: attributes[:content],
        }
      end
    end
  end
end
