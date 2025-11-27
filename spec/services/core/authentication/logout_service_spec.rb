# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Core::Authentication::LogoutService do
  let(:user) { create(:user) }
  let(:raw_refresh_token) { SecureRandom.urlsafe_base64(32) }
  let!(:refresh_token) do
    create(
      :refresh_token,
      user: user,
      token_digest: Digest::SHA256.hexdigest(raw_refresh_token)
    )
  end
  let(:service) { described_class.new(refresh_token: raw_refresh_token) }

  describe '#call' do
    context 'with a valid token' do
      it 'revokes the refresh token' do
        expect { service.call }.to change { refresh_token.reload.revoked? }.from(false).to(true)
      end

      it 'returns a successful result' do
        result = service.call
        expect(result).to be_success
        expect(result.data.message).to eq('Logged out successfully')
      end
    end

    context 'with an invalid token' do
      let(:service) { described_class.new(refresh_token: 'invalid-token') }

      it 'returns a failure result' do
        result = service.call
        expect(result).to be_failure
        expect(result.errors).to eq('Invalid refresh token')
      end
    end
  end
end
