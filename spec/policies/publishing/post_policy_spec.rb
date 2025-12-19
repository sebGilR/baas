# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Publishing::PostPolicy, type: :policy) do
  let(:account) { create(:account) }
  let(:blog) { create(:blog, account: account) }
  let(:author) { create(:user) }
  let(:post) { create(:post, account: account, blog: blog, author: author) }

  context "for an owner" do
    subject { described_class.new(AuthorizationContext.new(user: user, account: account), post) }

    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :owner) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }
    it { is_expected.to permit_action(:publish) }
    it { is_expected.to permit_action(:unpublish) }
  end

  context "for an editor" do
    subject { described_class.new(AuthorizationContext.new(user: user, account: account), post) }

    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :editor) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }
    it { is_expected.to permit_action(:publish) }
    it { is_expected.to permit_action(:unpublish) }
  end

  context "for an author" do
    subject { described_class.new(AuthorizationContext.new(user: user, account: account), post) }

    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :author) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }

    context "for their own posts" do
      let(:post) { create(:post, account: account, blog: blog, author: user) }

      it { is_expected.to permit_action(:update) }

      context "when post is a draft" do
        let(:post) { create(:post, account: account, blog: blog, author: user, status: :draft) }

        it { is_expected.to permit_action(:destroy) }
      end

      context "when post is published" do
        let(:post) { create(:post, :published, account: account, blog: blog, author: user) }

        it { is_expected.to forbid_action(:destroy) }
      end
    end

    context "for other authors' posts" do
      it { is_expected.to forbid_action(:update) }
      it { is_expected.to forbid_action(:destroy) }
    end

    it { is_expected.to forbid_action(:publish) }
    it { is_expected.to forbid_action(:unpublish) }
  end

  describe "Scope" do
    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :owner) }
    let!(:post_in_account) { create(:post, account: account, blog: blog, author: author) }
    let!(:post_in_other_account) { create(:post) }

    it "returns only posts in the user's account" do
      scope = described_class::Scope.new(AuthorizationContext.new(user: user, account: account), Post.all)
      expect(scope.resolve).to(include(post_in_account))
      expect(scope.resolve).not_to(include(post_in_other_account))
    end
  end
end
