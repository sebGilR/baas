# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Publishing::CategoryPolicy, type: :policy) do
  let(:account) { create(:account) }
  let(:category) { create(:category, account: account) }

  context "for an owner" do
    subject { described_class.new(user, category, AuthorizationContext.new(user: user, account: account)) }

    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :owner) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }
  end

  context "for an admin" do
    subject { described_class.new(user, category, AuthorizationContext.new(user: user, account: account)) }

    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :admin) }

    it { is_expected.to permit_action(:destroy) }
  end

  context "for an editor" do
    subject { described_class.new(user, category, AuthorizationContext.new(user: user, account: account)) }

    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :editor) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to forbid_action(:destroy) }
  end

  context "for an author" do
    subject { described_class.new(user, category, AuthorizationContext.new(user: user, account: account)) }

    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :author) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:update) }
    it { is_expected.to forbid_action(:destroy) }
  end

  describe "Scope" do
    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :owner) }
    let!(:category_in_account) { create(:category, account: account) }
    let!(:category_in_other_account) { create(:category) }

    it "returns only categories in the user's account" do
      scope = described_class::Scope.new(user, Category.all, AuthorizationContext.new(user: user, account: account))
      expect(scope.resolve).to(include(category_in_account))
      expect(scope.resolve).not_to(include(category_in_other_account))
    end
  end
end
