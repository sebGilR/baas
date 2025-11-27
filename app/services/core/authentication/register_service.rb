# frozen_string_literal: true

module Core
  module Authentication
    class RegisterService < ApplicationService
      def initialize(email:, password:, name:, account_name: nil)
        @email = email
        @password = password
        @name = name
        @account_name = account_name || "#{name}'s Account"
      end

      def call
        ActiveRecord::Base.transaction do
          user = create_user
          return failure(errors: user.errors.full_messages) unless user.persisted?

          account = create_account_for_user(user)
          return failure(errors: account.errors.full_messages) unless account.persisted?

          membership = create_membership(user, account)
          return failure(errors: membership.errors.full_messages) unless membership.persisted?

          tokens = generate_tokens(user, account)

          success(
            user: user,
            account: account,
            access_token: tokens[:access_token],
            refresh_token: tokens[:refresh_token],
            expires_in: 1800
          )
        end
      rescue => e
        failure(errors: e.message)
      end

      private

      attr_reader :email, :password, :name, :account_name

      def create_user
        User.create(
          email: email,
          password: password,
          name: name
        )
      end

      def create_account_for_user(user)
        Account.create(
          name: account_name,
          status: :active,
          plan: :free
        )
      end

      def create_membership(user, account)
        AccountMembership.create(
          user: user,
          account: account,
          role: :owner,
          status: :active
        )
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
          device_info: {} # Will add from request later
        )

        {
          access_token: access_result.data.access_token,
          refresh_token: refresh_token
        }
      end
    end
  end
end
