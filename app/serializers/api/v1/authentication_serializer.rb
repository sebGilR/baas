# frozen_string_literal: true

module Api
  module V1
    # Serializer for authentication responses (login, register, refresh)
    # Combines user, account, and token data into a single response
    #
    # @example
    #   Api::V1::AuthenticationSerializer.new(
    #     user: user,
    #     account: account,
    #     access_token: "jwt_token",
    #     refresh_token: "refresh_token",
    #     expires_in: 1800
    #   ).serializable_hash
    #
    # @example Using class method
    #   Api::V1::AuthenticationSerializer.render(user: user, ...)
    #
    class AuthenticationSerializer < ::BaseSerializer
      def initialize(user:, account:, access_token:, refresh_token:, expires_in:)
        @user = user
        @account = account
        @access_token = access_token
        @refresh_token = refresh_token
        @expires_in = expires_in
      end

      def serializable_hash
        {
          data: {
            type: "authentication",
            attributes: {
              user: user_data,
              account: account_data,
              access_token: @access_token,
              refresh_token: @refresh_token,
              token_type: "Bearer",
              expires_in: @expires_in,
            },
          },
        }
      end

      private

      def user_data
        UserSerializer.new(@user).serializable_hash[:data]
      end

      def account_data
        AccountSerializer.new(@account).serializable_hash[:data]
      end
    end
  end
end
