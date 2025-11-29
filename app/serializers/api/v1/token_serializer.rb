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
    #     expires_in: 1800
    #   ).serializable_hash
    #
    class TokenSerializer
      def initialize(access_token:, refresh_token:, expires_in:)
        @access_token = access_token
        @refresh_token = refresh_token
        @expires_in = expires_in
      end

      def serializable_hash
        {
          data: {
            type: "authentication",
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
