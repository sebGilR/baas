# frozen_string_literal: true

RSpec.shared_context "authenticated request" do
  let(:user) { create(:user) }
  let(:account) { create(:account) }
  let!(:membership) { create(:account_membership, user: user, account: account, role: :owner) }

  let(:auth_headers) do
    token = Core::Authentication::GenerateJwtService.call(
      user_id: user.public_id,
      account_id: account.public_id,
    ).token

    { "Authorization" => "Bearer #{token}" }
  end
end
