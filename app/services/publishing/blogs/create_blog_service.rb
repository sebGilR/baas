# frozen_string_literal: true

module Publishing
  module Blogs
    class CreateBlogService < ApplicationService
      def initialize(account:, user:, attributes:)
        @account = account
        @user = user
        @attributes = attributes.to_h.symbolize_keys
      end

      def call
        return failure(errors: "Account is required", code: Codes::VALIDATION_FAILED) unless account
        return failure(errors: "User is required", code: Codes::VALIDATION_FAILED) unless user

        blog = build_blog
        return failure(errors: blog.errors.full_messages, code: Codes::VALIDATION_FAILED) unless blog.save

        success(blog: blog)
      end

      private

      attr_reader :account, :user, :attributes

      def build_blog
        account.blogs.build(
          name: attributes[:name],
          slug: attributes[:slug],
          description: attributes[:description],
          settings: attributes[:settings] || {},
          status: :active
        )
      end
    end
  end
end
