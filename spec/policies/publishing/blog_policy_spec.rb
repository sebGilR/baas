# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Publishing::BlogPolicy, type: :policy) do
  let(:account) { create(:account) }
  let(:blog) { create(:blog, account: account) }

  context "for an owner" do
    subject { described_class.new(AuthorizationContext.new(user: user, account: account), blog) }

    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :owner) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }

    context "when creating" do
      subject { described_class.new(AuthorizationContext.new(user: user, account: account), Blog) }

      it { is_expected.to permit_action(:create) }
    end
  end

  context "for an admin" do
    subject { described_class.new(AuthorizationContext.new(user: user, account: account), blog) }

    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :admin) }

    it { is_expected.to permit_action(:destroy) }
  end

  context "for an editor" do
    subject { described_class.new(AuthorizationContext.new(user: user, account: account), blog) }

    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :editor) }

    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to forbid_action(:destroy) }
  end

  context "for an author" do
    subject { described_class.new(AuthorizationContext.new(user: user, account: account), blog) }

    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :author) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:update) }
    it { is_expected.to forbid_action(:destroy) }
  end

  context "for a user without membership" do
    subject { described_class.new(AuthorizationContext.new(user: user, account: account), blog) }

    let(:user) { create(:user) }

    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:update) }
    it { is_expected.to forbid_action(:destroy) }
  end

  describe "Scope" do
    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :owner) }
    let!(:blog_in_account) { create(:blog, account: account) }
    let!(:blog_in_other_account) { create(:blog) }

    it "returns only blogs in the user's account" do
      # Note: Pundit scopes need context with account, this test may need adjustment
      # based on how the scope is called with AuthorizationContext
      scope = described_class::Scope.new(AuthorizationContext.new(user: user, account: account), Blog.all)
      expect(scope.resolve).to(include(blog_in_account))
      expect(scope.resolve).not_to(include(blog_in_other_account))
    end
  end
end
