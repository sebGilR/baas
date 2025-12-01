# frozen_string_literal: true

module Api
  module V1
    class TagSerializer
      include JSONAPI::Serializer

      set_id :public_id
      set_type :tag

      attributes :name, :slug, :color, :created_at, :updated_at

      attribute :post_count do |tag|
        tag.post_count
      end

      attribute :usage_count do |tag|
        tag.usage_count
      end
    end
  end
end
