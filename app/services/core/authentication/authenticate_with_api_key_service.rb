# frozen_string_literal: true

module Core
  module Authentication
    # Service to authenticate requests using API keys
    # API key format: "ak_live_XXXXXXXX.secret" or "ak_test_XXXXXXXX.secret"
    #
    # @example
    #   result = AuthenticateWithApiKeyService.call(
    #     raw_token: "ak_live_abc12345.xyzSecretHere",
    #     ip_address: "127.0.0.1"
    #   )
    #   if result.success?
    #     user = result.user
    #     account = result.account
    #     api_key = result.api_key
    #   end
    #
    class AuthenticateWithApiKeyService < ApplicationService
      def initialize(raw_token:, ip_address: nil)
        @raw_token = raw_token
        @ip_address = ip_address
      end

      def call
        prefix, raw_secret = parse_token
        return failure(errors: "Invalid API key format", code: Codes::INVALID_CREDENTIALS) unless prefix && raw_secret

        api_key = find_api_key(prefix)
        return failure(errors: "API key not found", code: Codes::NOT_FOUND) unless api_key
        return failure(errors: "API key has been revoked", code: Codes::INVALID_CREDENTIALS) if api_key.revoked?
        return failure(errors: "API key has expired", code: Codes::INVALID_CREDENTIALS) if api_key.expired?
        return failure(errors: "Invalid API key secret", code: Codes::INVALID_CREDENTIALS) unless api_key.valid_secret?(raw_secret)

        # Record usage asynchronously (non-blocking)
        api_key.record_usage!(ip_address: ip_address)

        success(
          user: api_key.user,
          account: api_key.account,
          api_key: api_key
        )
      end

      private

      attr_reader :raw_token, :ip_address

      # Parse token into prefix and secret
      # Format: "ak_live_XXXXXXXX.secret" or "ak_test_XXXXXXXX.secret"
      def parse_token
        return [nil, nil] if raw_token.blank?

        parts = raw_token.to_s.split(".", 2)
        return [nil, nil] unless parts.length == 2

        prefix = parts[0]
        raw_secret = parts[1]

        # Validate prefix format
        return [nil, nil] unless valid_prefix?(prefix)

        [prefix, raw_secret]
      end

      def valid_prefix?(prefix)
        prefix.match?(/\Aak_(live|test)_[A-Za-z0-9]{8}\z/)
      end

      def find_api_key(prefix)
        ApiKey.find_by_prefix(prefix)
      end
    end
  end
end
