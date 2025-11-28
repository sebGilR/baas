# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Core::Authentication::RefreshTokenService) do
  let(:user) { create(:user) }
  let!(:account) { create(:account) }
  let!(:membership) { create(:account_membership, user: user, account: account) }
  let(:raw_refresh_token) { SecureRandom.urlsafe_base64(32) }
  let!(:refresh_token) do
    create(
      :refresh_token,
      user: user,
      token_digest: Digest::SHA256.hexdigest(raw_refresh_token),
    )
  end
  let(:service) { described_class.new(refresh_token: raw_refresh_token) }

  describe "#call" do
    context "with a valid token" do
      it "returns a successful result with new tokens" do
        result = service.call
        expect(result).to(be_success)
        expect(result.data.access_token).to(be_a(String))
        expect(result.data.refresh_token).to(be_a(String))
        expect(result.data.refresh_token).not_to(eq(raw_refresh_token))
      end

      it "revokes the old token" do
        service.call
        expect(refresh_token.reload.revoked?).to(be(true))
      end

      it "creates a new refresh token" do
        expect { service.call }.to(change(RefreshToken, :count).by(1))
      end
    end

    context "with an expired token" do
      before { refresh_token.update(expires_at: 1.day.ago) }

      it "returns a failure result" do
        result = service.call
        expect(result).to(be_failure)
        expect(result.errors).to(eq("Token expired"))
      end
    end

    context "with a revoked token" do
      before { refresh_token.revoke! }

      it "returns a failure result" do
        result = service.call
        expect(result).to(be_failure)
        expect(result.errors).to(eq("Token revoked"))
      end
    end

    context "with an invalid token" do
      let(:service) { described_class.new(refresh_token: "invalid-token") }

      it "returns a failure result" do
        result = service.call
        expect(result).to(be_failure)
        expect(result.errors).to(eq("Invalid refresh token"))
      end
    end
  end
end
