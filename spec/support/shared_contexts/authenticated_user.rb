# frozen_string_literal: true

RSpec.shared_context("with authenticated user") do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:account_membership) { create(:account_membership, user: user, account: account, role: :owner) }

  let(:access_token) do
    account_membership # ensure membership exists
    result = Core::Authentication::GenerateJwtService.call(user: user, account: account)
    result.data[:access_token]
  end

  let(:authorization_header) { "Bearer #{access_token}" }
end

RSpec.shared_context("with authenticated admin") do
  include_context "with authenticated user"

  before do
    account_membership.update!(role: :admin)
  end
end

RSpec.shared_context("with authenticated member") do
  include_context "with authenticated user"

  before do
    account_membership.update!(role: :member)
  end
end
