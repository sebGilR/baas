# frozen_string_literal: true

module Core
  module Authentication
    # Service to create a new API key for a user within an account
    # Returns the raw token only once - it cannot be retrieved later
    #
    # @example
    #   result = CreateApiKeyService.call(
    #     user: current_user,
    #     account: current_account,
    #     name: "Postman Development",
    #     scopes: ["posts:read", "posts:write"],
    #     environment: :live
    #   )
    #   if result.success?
    #     raw_token = result.raw_token  # Only available at creation!
    #     api_key = result.api_key
    #   end
    #
    class CreateApiKeyService < ApplicationService
      def initialize(user:, account:, name:, scopes: [], environment: :live, expires_at: nil)
        @user = user
        @account = account
        @name = name
        @scopes = scopes
        @environment = environment
        @expires_at = expires_at
      end

      def call
        return failure(errors: "User not found", code: Codes::NOT_FOUND) unless user
        return failure(errors: "Account not found", code: Codes::NOT_FOUND) unless account
        return failure(errors: "User does not belong to account", code: Codes::FORBIDDEN) unless user_belongs_to_account?

        api_key, raw_token = ApiKey.generate(
          user: user,
          account: account,
          name: name,
          scopes: normalize_scopes,
          environment: environment,
          expires_at: expires_at
        )

        if api_key.save
          success(api_key: api_key, raw_token: raw_token)
        else
          failure(errors: api_key.errors.full_messages.join(", "), code: Codes::VALIDATION_FAILED)
        end
      end

      private

      attr_reader :user, :account, :name, :scopes, :environment, :expires_at

      def user_belongs_to_account?
        user.accounts.include?(account)
      end

      def normalize_scopes
        Array(scopes).map(&:to_s).uniq
      end
    end
  end
end
