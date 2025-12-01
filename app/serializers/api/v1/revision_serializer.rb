# frozen_string_literal: true

module Api
  module V1
    class RevisionSerializer
      include JSONAPI::Serializer

      set_id :public_id
      set_type :revision

      attributes :title, :content, :revision_number, :created_at

      attribute :metadata do |revision|
        revision.metadata || {}
      end

      attribute :word_count do |revision|
        revision.word_count
      end

      belongs_to :post, serializer: PostSerializer, id_method_name: :public_id
      belongs_to :created_by, serializer: UserSerializer, id_method_name: :public_id
    end
  end
end
