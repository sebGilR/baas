# frozen_string_literal: true

module Api
  module V1
    class PublicPostSerializer
      include JSONAPI::Serializer

      set_type :post
      set_id :slug

      attributes :title,
        :slug,
        :excerpt,
        :content_html,
        :content_text,
        :seo_title,
        :seo_description,
        :reading_time_minutes,
        :published_at,
        :updated_at,
        :featured,
        :content_schema_version

      attribute :metadata do |post|
        post.metadata || {}
      end

      attribute :canonical_url do |post|
        post.metadata&.dig("canonical_url")
      end

      belongs_to :blog,
        serializer: PublicBlogSerializer,
        id_method_name: :slug do |post, params|
        params[:blog] || post.blog
      end

      belongs_to :category,
        serializer: CategorySerializer,
        id_method_name: :public_id,
        if: ->(post) { post.category.present? }

      has_many :tags,
        serializer: TagSerializer,
        id_method_name: :public_id
    end
  end
end
