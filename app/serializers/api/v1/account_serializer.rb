# frozen_string_literal: true

module Api
  module V1
    class AccountSerializer
      include JSONAPI::Serializer

      set_id :public_id
      attributes :name, :slug, :plan, :status, :created_at
    end
  end
end
