# frozen_string_literal: true

module Core
  module Authentication
    class DecodeJwtService < ApplicationService
      def initialize(token:)
        @token = token
      end

      def call
        payload = decode_token
        return failure(errors: "Invalid token") unless payload

        success(payload: payload)
      rescue JWT::ExpiredSignature
        failure(errors: "Token has expired")
      rescue JWT::DecodeError
        failure(errors: "Invalid token")
      end

      private

      attr_reader :token

      def decode_token
        JWT.decode(token, jwt_secret, true, { algorithm: "HS256" }).first
      end

      def jwt_secret
        Rails.application.credentials.secret_key_base || Rails.application.secret_key_base
      end
    end
  end
end
