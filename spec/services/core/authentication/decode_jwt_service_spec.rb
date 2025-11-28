# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Core::Authentication::DecodeJwtService) do
  let(:user) { create(:user) }
  let(:account) { create(:account) }
  let!(:membership) { create(:account_membership, user: user, account: account, role: :owner) }
  let(:jwt_secret) { Rails.application.credentials.secret_key_base }

  describe "#call" do
    context "with a valid token" do
      let(:token) { Core::Authentication::GenerateJwtService.call(user: user, account: account).data.access_token }
      let(:service) { described_class.new(token: token) }

      it "returns a successful result with the payload" do
        result = service.call
        expect(result).to(be_success)
        expect(result.data.payload).to(be_a(Hash))
        expect(result.data.payload["sub"]).to(eq(user.public_id))
      end
    end

    context "with an expired token" do
      let(:token) do
        payload = { sub: user.public_id, exp: 1.minute.ago.to_i }
        JWT.encode(payload, jwt_secret, "HS256")
      end
      let(:service) { described_class.new(token: token) }

      it "returns a failure result with an expired message" do
        result = service.call
        expect(result).to(be_failure)
        expect(result.errors).to(eq("Token has expired"))
      end
    end

    context "with an invalid token" do
      let(:service) { described_class.new(token: "invalid.token") }

      it "returns a failure result with an invalid message" do
        result = service.call
        expect(result).to(be_failure)
        expect(result.errors).to(eq("Invalid token"))
      end
    end
  end
end
