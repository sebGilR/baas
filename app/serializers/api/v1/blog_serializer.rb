# frozen_string_literal: true

module Api
  module V1
    class BlogSerializer
      include JSONAPI::Serializer

      set_id :public_id
      set_type :blog

      attributes :name, :slug, :description, :status, :created_at, :updated_at

      attribute :settings do |blog|
        blog.settings || {}
      end

      attribute :post_count do |blog|
        blog.posts.count
      end

      belongs_to :account, serializer: AccountSerializer, id_method_name: :public_id

      has_many :posts, serializer: PostSerializer, id_method_name: :public_id do |blog|
        blog.posts.limit(10)
      end
    end
  end
end
