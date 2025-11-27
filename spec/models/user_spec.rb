# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { create(:user) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_least(2) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to allow_value('user@example.com').for(:email) }
    it { is_expected.not_to allow_value('user@.com').for(:email) }


    it { is_expected.to have_secure_password }
  end

  describe 'associations' do
    it { is_expected.to have_many(:account_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:accounts).through(:account_memberships) }
    it { is_expected.to have_many(:refresh_tokens).dependent(:destroy) }
  end

  describe 'callbacks' do
    it 'normalizes the email to lowercase and strips whitespace' do
      user = build(:user, email: '  TEST@EXAMPLE.COM  ')
      user.valid?
      expect(user.email).to eq('test@example.com')
    end
  end

  describe '#primary_account' do
    let(:user) { create(:user) }
    let!(:account1) { create(:account) }
    let!(:account2) { create(:account) }

    before do
      create(:account_membership, user: user, account: account1)
      create(:account_membership, user: user, account: account2)
    end

    it 'returns the first associated account' do
      expect(user.primary_account).to eq(account1)
    end
  end

  describe '#role_for_account' do
    let(:user) { create(:user) }
    let(:account) { create(:account) }

    context 'when user has a role in the account' do
      before do
        create(:account_membership, user: user, account: account, role: :admin)
      end

      it 'returns the role' do
        expect(user.role_for_account(account)).to eq('admin')
      end
    end

    context 'when user does not have a role in the account' do
      it 'returns nil' do
        expect(user.role_for_account(account)).to be_nil
      end
    end
  end
end
