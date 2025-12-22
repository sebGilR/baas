# frozen_string_literal: true

module Core
  module Authentication
    class LoginService < ApplicationService
      def initialize(email:, password:, device_info: {})
        @email = email
        @password = password
        @device_info = device_info
      end

      def call
        user = find_user
        return invalid_credentials unless user
        return invalid_credentials unless user.authenticate(password)

        account = user.primary_account
        return failure(errors: "No account found", code: Codes::NOT_FOUND) unless account

        tokens = generate_tokens(user, account)

        success(
          user: user,
          account: account,
          access_token: tokens[:access_token],
          refresh_token: tokens[:refresh_token],
          expires_in: Core::Authentication::ACCESS_TOKEN_EXPIRES_IN,
        )
      end

      private

      attr_reader :email, :password, :device_info

      def invalid_credentials
        failure(errors: "Invalid email or password", code: Codes::INVALID_CREDENTIALS)
      end

      def find_user
        User.find_by(email: email.downcase.strip)
      end

      def generate_tokens(user, account)
        # Access token
        access_result = GenerateJwtService.call(user: user, account: account)

        # Refresh token
        refresh_token = SecureRandom.urlsafe_base64(32)
        jti = SecureRandom.uuid

        RefreshToken.create!(
          user: user,
          jti: jti,
          token_digest: Digest::SHA256.hexdigest(refresh_token),
          expires_at: 30.days.from_now,
          device_info: device_info,
        )

        {
          access_token: access_result.data.access_token,
          refresh_token: refresh_token,
        }
      end
    end
  end
end
