# frozen_string_literal: true

module Api
  module V1
    class DraftSerializer
      include JSONAPI::Serializer

      set_id :public_id
      set_type :draft

      attributes :title, :content, :content_json, :content_html, :content_text,
                 :autosaved_at, :created_at, :updated_at

      attribute :metadata do |draft|
        draft.metadata || {}
      end

      attribute :word_count do |draft|
        draft.word_count
      end

      attribute :last_saved do |draft|
        draft.last_saved
      end

      belongs_to :blog, serializer: BlogSerializer, id_method_name: :public_id
      belongs_to :author, serializer: UserSerializer, id_method_name: :public_id
      belongs_to :post, serializer: PostSerializer, id_method_name: :public_id, if: proc { |draft| draft.post.present? }

      has_many :tags, serializer: TagSerializer, id_method_name: :public_id
    end
  end
end
