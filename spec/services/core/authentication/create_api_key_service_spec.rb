# frozen_string_literal: true

require "rails_helper"

RSpec.describe Core::Authentication::CreateApiKeyService do
  describe "#call" do
    let(:account) { create(:account) }
    let(:user) { create(:user) }
    let!(:account_membership) { create(:account_membership, user: user, account: account) }

    # Reload user to refresh the accounts association after membership is created
    before { user.reload }

    context "with valid attributes" do
      let(:default_scopes) { ["posts:read"] }

      it "creates an API key" do
        result = described_class.call(
          user: user,
          account: account,
          name: "Test Key",
          scopes: ["posts:read", "posts:write"]
        )

        expect(result).to be_success
        expect(result.api_key).to be_persisted
        expect(result.api_key.name).to eq("Test Key")
        expect(result.api_key.scopes).to eq(["posts:read", "posts:write"])
      end

      it "returns the raw token only at creation" do
        result = described_class.call(
          user: user,
          account: account,
          name: "Test Key",
          scopes: default_scopes
        )

        expect(result.raw_token).to start_with("ak_live_")
        expect(result.raw_token).to include(".")
      end

      it "creates a live environment key by default" do
        result = described_class.call(
          user: user,
          account: account,
          name: "Test Key",
          scopes: default_scopes
        )

        expect(result.api_key.environment_live?).to be true
      end

      it "creates a test environment key when specified" do
        result = described_class.call(
          user: user,
          account: account,
          name: "Test Key",
          scopes: default_scopes,
          environment: :test
        )

        expect(result.api_key.environment_test?).to be true
        expect(result.raw_token).to start_with("ak_test_")
      end

      it "sets expiration when specified" do
        expires_at = 30.days.from_now

        result = described_class.call(
          user: user,
          account: account,
          name: "Test Key",
          scopes: default_scopes,
          expires_at: expires_at
        )

        expect(result.api_key.expires_at).to be_within(1.second).of(expires_at)
      end
    end

    context "with invalid user" do
      it "returns failure for nil user" do
        result = described_class.call(
          user: nil,
          account: account,
          name: "Test Key"
        )

        expect(result).to be_failure
        expect(result.errors).to include("User not found")
      end
    end

    context "with invalid account" do
      it "returns failure for nil account" do
        result = described_class.call(
          user: user,
          account: nil,
          name: "Test Key"
        )

        expect(result).to be_failure
        expect(result.errors).to include("Account not found")
      end
    end

    context "when user does not belong to account" do
      let(:other_account) { create(:account) }

      it "returns failure" do
        result = described_class.call(
          user: user,
          account: other_account,
          name: "Test Key"
        )

        expect(result).to be_failure
        expect(result.errors).to include("User does not belong to account")
      end
    end

    context "with validation errors" do
      it "returns failure for blank name" do
        result = described_class.call(
          user: user,
          account: account,
          name: ""
        )

        expect(result).to be_failure
        expect(result.errors).to include(/Name/)
      end
    end
  end
end
