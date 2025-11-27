# frozen_string_literal: true

module Core
  module Authentication
    class RefreshTokenService < ApplicationService
      def initialize(refresh_token:)
        @refresh_token = refresh_token
      end

      def call
        token_record = find_token_record
        return failure(errors: 'Invalid refresh token') unless token_record
        return failure(errors: 'Token expired') if token_record.expired?
        return failure(errors: 'Token revoked') if token_record.revoked?

        user = token_record.user
        account = user.primary_account

        # Generate new tokens
        new_tokens = rotate_tokens(token_record, user, account)

        success(
          user: user,
          account: account,
          access_token: new_tokens[:access_token],
          refresh_token: new_tokens[:refresh_token],
          expires_in: 1800
        )
      end

      private

      attr_reader :refresh_token

      def find_token_record
        token_digest = Digest::SHA256.hexdigest(refresh_token)
        RefreshToken.find_by(token_digest: token_digest)
      end

      def rotate_tokens(old_token, user, account)
        ActiveRecord::Base.transaction do
          # Revoke old token
          old_token.revoke!

          # Generate new access token
          access_result = GenerateJwtService.call(user: user, account: account)

          # Generate new refresh token
          new_refresh_token = SecureRandom.urlsafe_base64(32)
          jti = SecureRandom.uuid

          RefreshToken.create!(
            user: user,
            jti: jti,
            token_digest: Digest::SHA256.hexdigest(new_refresh_token),
            expires_at: 30.days.from_now,
            device_info: old_token.device_info
          )

          {
            access_token: access_result.data.access_token,
            refresh_token: new_refresh_token
          }
        end
      end
    end
  end
end
