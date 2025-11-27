# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Core::Authentication::LoginService do
  let(:password) { 'Password123!' }
  let!(:user) { create(:user, password: password) }
  let!(:account) { create(:account) }
  let!(:membership) { create(:account_membership, user: user, account: account) }
  let(:service) { described_class.new(email: user.email, password: password) }

  describe '#call' do
    context 'with valid credentials' do
      it 'returns a successful result with tokens' do
        result = service.call
        expect(result).to be_success
        expect(result.data.access_token).to be_a(String)
        expect(result.data.refresh_token).to be_a(String)
      end

      it 'creates a new refresh token' do
        expect { service.call }.to change(RefreshToken, :count).by(1)
      end
    end

    context 'with invalid credentials' do
      let(:service) { described_class.new(email: user.email, password: 'wrong-password') }

      it 'returns a failure result' do
        result = service.call
        expect(result).to be_failure
        expect(result.errors).to eq('Invalid email or password')
      end

      it 'does not create a refresh token' do
        expect { service.call }.not_to change(RefreshToken, :count)
      end
    end

    context 'when user has no account' do
      let!(:user_without_account) { create(:user) }
      let(:service) { described_class.new(email: user_without_account.email, password: 'Password123!') }

      it 'returns a failure result' do
        result = service.call
        expect(result).to be_failure
        expect(result.errors).to eq('No account found')
      end
    end
  end
end
