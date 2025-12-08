# frozen_string_literal: true

module Api
  module V1
    class ApiKeySerializer
      include JSONAPI::Serializer

      set_type :api_key
      set_id :public_id

      # Basic attributes (always returned)
      attributes :name, :prefix, :environment, :scopes, :status,
                 :created_at, :expires_at, :last_used_at

      # Computed attributes
      attribute :masked_prefix do |api_key|
        api_key.masked_prefix
      end

      attribute :status do |api_key|
        api_key.status.to_s
      end

      attribute :is_active do |api_key|
        api_key.active?
      end

      # Relationships
      belongs_to :user, serializer: UserSerializer, id_method_name: :public_id
      belongs_to :account, serializer: AccountSerializer, id_method_name: :public_id
    end
  end
end
