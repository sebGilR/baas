# frozen_string_literal: true

module Api
  module V1
    # Serializer for token refresh responses
    # Returns only token data without user/account info
    #
    # @example
    #   Api::V1::TokenSerializer.new(
    #     access_token: "jwt_token",
    #     refresh_token: "refresh_token",
    #     expires_in: 86400
    #   ).serializable_hash
    #
    # @example Using class method
    #   Api::V1::TokenSerializer.render(access_token: token, ...)
    #
    class TokenSerializer < ::BaseSerializer
      def initialize(access_token:, refresh_token:, expires_in:)
        @access_token = access_token
        @refresh_token = refresh_token
        @expires_in = expires_in
      end

      def serializable_hash
        {
          data: {
            type: "token",
            attributes: {
              access_token: @access_token,
              refresh_token: @refresh_token,
              token_type: "Bearer",
              expires_in: @expires_in,
            },
          },
        }
      end
    end
  end
end
