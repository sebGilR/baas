# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Core::Authentication::GenerateJwtService) do
  let(:user) { create(:user) }
  let(:token) { service.call.data.access_token }
  let(:account) { create(:account) }
  let!(:membership) { create(:account_membership, user: user, account: account, role: :owner) }
  let(:service) { described_class.new(user: user, account: account) }

  include_context "with decoded JWT payload"

  describe "#call" do
    it "returns a successful result with an access token" do
      result = service.call
      expect(result).to(be_success)
      expect(result.data.access_token).to(be_a(String))
    end

    it "encodes the correct payload in the token" do
      freeze_time do
        expect(payload).to(include(
          "sub" => user.public_id,
          "account_id" => account.public_id,
          "email" => user.email,
          "role" => "owner",
        ))
        expect(payload["exp"]).to(be_within(1.second).of(30.minutes.from_now.to_i))
        expect(payload["iat"]).to(be_within(1.second).of(Time.current.to_i))
      end
    end
  end
end
