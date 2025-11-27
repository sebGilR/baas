# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Core::Authentication::GenerateJwtService do
  let(:user) { create(:user) }
  let(:account) { create(:account) }
  let!(:membership) { create(:account_membership, user: user, account: account, role: :owner) }
  let(:service) { described_class.new(user: user, account: account) }

  describe '#call' do
    it 'returns a successful result with an access token' do
      result = service.call
      expect(result).to be_success
      expect(result.data.access_token).to be_a(String)
    end

    it 'encodes the correct payload in the token' do
      freeze_time do
        result = service.call
        decoded_token = JWT.decode(result.data.access_token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' })
        payload = decoded_token.first

        expect(payload['sub']).to eq(user.public_id)
        expect(payload['account_id']).to eq(account.public_id)
        expect(payload['email']).to eq(user.email)
        expect(payload['role']).to eq('owner')
        expect(payload['exp']).to eq(30.minutes.from_now.to_i)
        expect(payload['iat']).to eq(Time.current.to_i)
      end
    end
  end
end
