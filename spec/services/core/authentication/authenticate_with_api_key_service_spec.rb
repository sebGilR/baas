# frozen_string_literal: true

require "rails_helper"

RSpec.describe Core::Authentication::AuthenticateWithApiKeyService do
  describe "#call" do
    let(:user) { create(:user) }
    let(:account) { create(:account) }
    let(:raw_secret) { "test_secret_12345" }
    let(:prefix) { "ak_live_abc12345" }
    let(:raw_token) { "#{prefix}.#{raw_secret}" }

    let!(:api_key) do
      create(:api_key,
        user: user,
        account: account,
        prefix: prefix,
        secret_digest: BCrypt::Password.create(raw_secret, cost: 4)
      )
    end

    context "with valid token" do
      it "returns success with user and account" do
        result = described_class.call(raw_token: raw_token)

        expect(result).to be_success
        expect(result.user).to eq(user)
        expect(result.account).to eq(account)
        expect(result.api_key).to eq(api_key)
      end

      it "records usage" do
        expect {
          described_class.call(raw_token: raw_token, ip_address: "127.0.0.1")
        }.to change { api_key.reload.last_used_at }

        expect(api_key.last_used_ip).to eq("127.0.0.1")
      end
    end

    context "with invalid token format" do
      it "returns failure for missing dot separator" do
        result = described_class.call(raw_token: "ak_live_abc12345noseparator")

        expect(result).to be_failure
        expect(result.errors).to include("Invalid API key format")
      end

      it "returns failure for invalid prefix format" do
        result = described_class.call(raw_token: "invalid_prefix.secret")

        expect(result).to be_failure
        expect(result.errors).to include("Invalid API key format")
      end

      it "returns failure for blank token" do
        result = described_class.call(raw_token: "")

        expect(result).to be_failure
        expect(result.errors).to include("Invalid API key format")
      end
    end

    context "with unknown prefix" do
      it "returns failure" do
        result = described_class.call(raw_token: "ak_live_unknown1.secret")

        expect(result).to be_failure
        expect(result.errors).to include("API key not found")
      end
    end

    context "with invalid secret" do
      it "returns failure" do
        result = described_class.call(raw_token: "#{prefix}.wrong_secret")

        expect(result).to be_failure
        expect(result.errors).to include("Invalid API key secret")
      end
    end

    context "with revoked key" do
      before { api_key.revoke! }

      it "returns failure" do
        result = described_class.call(raw_token: raw_token)

        expect(result).to be_failure
        expect(result.errors).to include("API key has been revoked")
      end
    end

    context "with expired key" do
      before { api_key.update!(expires_at: 1.day.ago) }

      it "returns failure" do
        result = described_class.call(raw_token: raw_token)

        expect(result).to be_failure
        expect(result.errors).to include("API key has expired")
      end
    end

    context "with test environment key" do
      let(:prefix) { "ak_test_abc12345" }

      it "authenticates successfully" do
        api_key.update!(prefix: prefix, environment: :test)

        result = described_class.call(raw_token: raw_token)

        expect(result).to be_success
        expect(result.api_key.environment_test?).to be true
      end
    end
  end
end
