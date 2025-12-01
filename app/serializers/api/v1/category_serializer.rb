# frozen_string_literal: true

module Api
  module V1
    class CategorySerializer
      include JSONAPI::Serializer

      set_id :public_id
      set_type :category

      attributes :name, :slug, :description, :position, :created_at, :updated_at

      attribute :depth do |category|
        category.depth
      end

      attribute :full_path do |category|
        category.full_path
      end

      attribute :post_count do |category|
        category.post_count
      end

      attribute :is_root do |category|
        category.root?
      end

      attribute :is_leaf do |category|
        category.leaf?
      end

      belongs_to :parent, serializer: CategorySerializer, id_method_name: :public_id, if: proc { |category| category.parent.present? }

      has_many :children, serializer: CategorySerializer, id_method_name: :public_id
    end
  end
end
