# frozen_string_literal: true

module Api
  module V1
    class UserSerializer
      include JSONAPI::Serializer

      set_id :public_id
      attributes :email, :name, :created_at
    end
  end
end
