# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Publishing::TagPolicy, type: :policy) do
  let(:account) { create(:account) }
  let(:tag) { create(:tag, account: account) }

  context "for an owner" do
    subject { described_class.new(user, tag, AuthorizationContext.new(user: user, account: account)) }

    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :owner) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }
  end

  context "for an admin" do
    subject { described_class.new(user, tag, AuthorizationContext.new(user: user, account: account)) }

    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :admin) }

    it { is_expected.to permit_action(:destroy) }
  end

  context "for an editor" do
    subject { described_class.new(user, tag, AuthorizationContext.new(user: user, account: account)) }

    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :editor) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to forbid_action(:destroy) }
  end

  context "for an author" do
    subject { described_class.new(user, tag, AuthorizationContext.new(user: user, account: account)) }

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
    let!(:tag_in_account) { create(:tag, account: account) }
    let!(:tag_in_other_account) { create(:tag) }

    it "returns only tags in the user's account" do
      scope = described_class::Scope.new(user, Tag.all, AuthorizationContext.new(user: user, account: account))
      expect(scope.resolve).to(include(tag_in_account))
      expect(scope.resolve).not_to(include(tag_in_other_account))
    end
  end
end
