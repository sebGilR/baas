# frozen_string_literal: true

module Core
  module Authentication
    class GenerateJwtService < ApplicationService
      def initialize(user:, account:)
        @user = user
        @account = account
      end

      def call
        access_token = generate_access_token
        success(access_token: access_token)
      end

      private

      attr_reader :user, :account

      def generate_access_token
        payload = {
          sub: user.public_id,
          account_id: account.public_id,
          email: user.email,
          role: user.role_for_account(account),
          exp: 30.minutes.from_now.to_i,
          iat: Time.current.to_i
        }

        JWT.encode(payload, jwt_secret, 'HS256')
      end

      def jwt_secret
        Rails.application.credentials.secret_key_base
      end
    end
  end
end
