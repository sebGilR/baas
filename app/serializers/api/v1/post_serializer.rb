# frozen_string_literal: true

module Api
  module V1
    class PostSerializer
      include JSONAPI::Serializer

      set_id :public_id
      set_type :post

      attributes :title,
        :slug,
        :content,
        :content_json,
        :content_html,
        :content_text,
        :excerpt,
        :status,
        :published_at,
        :scheduled_for,
        :featured,
        :seo_title,
        :seo_description,
        :reading_time_minutes,
        :content_schema_version,
        :created_at,
        :updated_at

      attribute :metadata do |post|
        post.metadata || {}
      end

      belongs_to :blog, serializer: BlogSerializer, id_method_name: :public_id
      belongs_to :author, serializer: UserSerializer, id_method_name: :public_id
      belongs_to :category, serializer: CategorySerializer, id_method_name: :public_id, if: proc { |post| post.category.present? }

      has_many :tags, serializer: TagSerializer, id_method_name: :public_id
      has_many :revisions, serializer: RevisionSerializer, id_method_name: :public_id do |post|
        post.revisions.ordered.limit(5)
      end
    end
  end
end
