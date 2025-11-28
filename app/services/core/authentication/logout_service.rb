# frozen_string_literal: true

module Core
  module Authentication
    class LogoutService < ApplicationService
      def initialize(refresh_token:)
        @refresh_token = refresh_token
      end

      def call
        token_record = find_token_record
        return failure(errors: "Invalid refresh token") unless token_record

        token_record.revoke!

        success(message: "Logged out successfully")
      end

      private

      attr_reader :refresh_token

      def find_token_record
        token_digest = Digest::SHA256.hexdigest(refresh_token)
        RefreshToken.find_by(token_digest: token_digest)
      end
    end
  end
end
