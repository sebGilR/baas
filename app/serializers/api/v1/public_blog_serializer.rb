# frozen_string_literal: true

module Api
  module V1
    class PublicBlogSerializer
      include JSONAPI::Serializer

      set_type :blog
      set_id :slug

      attributes :name, :slug, :description

      attribute :settings do |blog|
        blog.settings || {}
      end
    end
  end
end
