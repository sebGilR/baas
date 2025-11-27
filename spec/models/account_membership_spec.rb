# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountMembership, type: :model do
  describe 'validations' do
    subject { build(:account_membership) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:account_id).with_message('already a member of this account') }

  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:account) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:role).with_values(owner: 0, admin: 1, editor: 2, author: 3, viewer: 4).with_prefix }
    it { is_expected.to define_enum_for(:status).with_values(invited: 0, active: 1, suspended: 2).with_prefix }
  end

  describe 'scopes' do
    let!(:active_membership) { create(:account_membership, status: :active) }
    let!(:invited_membership) { create(:account_membership, status: :invited) }
    let(:account) { create(:account) }
    let!(:membership_for_account) { create(:account_membership, account: account) }
    let!(:other_membership) { create(:account_membership) }

    it 'returns only active memberships' do
      expect(AccountMembership.active).to include(active_membership)
      expect(AccountMembership.active).not_to include(invited_membership)
    end

    it 'returns memberships for a specific account' do
      expect(AccountMembership.for_account(account)).to include(membership_for_account)
      expect(AccountMembership.for_account(account)).not_to include(other_membership)
    end
  end

  describe 'instance methods' do
    context '#can_manage_users?' do
      it 'returns true for owner' do
        expect(build(:account_membership, role: :owner).can_manage_users?).to be true
      end

      it 'returns true for admin' do
        expect(build(:account_membership, role: :admin).can_manage_users?).to be true
      end

      it 'returns false for editor' do
        expect(build(:account_membership, role: :editor).can_manage_users?).to be false
      end
    end

    context '#can_publish?' do
      it 'returns true for owner' do
        expect(build(:account_membership, role: :owner).can_publish?).to be true
      end

      it 'returns true for admin' do
        expect(build(:account_membership, role: :admin).can_publish?).to be true
      end

      it 'returns true for editor' do
        expect(build(:account_membership, role: :editor).can_publish?).to be true
      end

      it 'returns false for author' do
        expect(build(:account_membership, role: :author).can_publish?).to be false
      end
    end
  end
end
