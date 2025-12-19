# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Publishing::DraftPolicy, type: :policy) do
  let(:account) { create(:account) }
  let(:blog) { create(:blog, account: account) }
  let(:draft_author) { create(:user) }
  let(:draft) { create(:draft, account: account, blog: blog, author: draft_author) }

  context "for an owner" do
    subject { described_class.new(AuthorizationContext.new(user: user, account: account), draft) }

    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :owner) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }
    it { is_expected.to permit_action(:autosave) }
    it { is_expected.to permit_action(:convert_to_post) }
  end

  context "for an editor" do
    subject { described_class.new(AuthorizationContext.new(user: user, account: account), draft) }

    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :editor) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }
    it { is_expected.to permit_action(:autosave) }
    it { is_expected.to permit_action(:convert_to_post) }
  end

  context "for an author" do
    subject { described_class.new(AuthorizationContext.new(user: user, account: account), draft) }

    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :author) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:create) }

    context "for their own drafts" do
      let(:draft) { create(:draft, account: account, blog: blog, author: user) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:update) }
      it { is_expected.to permit_action(:destroy) }
      it { is_expected.to permit_action(:autosave) }
      it { is_expected.to permit_action(:convert_to_post) }
    end

    context "for other authors' drafts" do
      it { is_expected.to forbid_action(:show) }
      it { is_expected.to forbid_action(:update) }
      it { is_expected.to forbid_action(:destroy) }
      it { is_expected.to forbid_action(:autosave) }
      it { is_expected.to forbid_action(:convert_to_post) }
    end
  end

  describe "Scope" do
    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :author) }
    let!(:own_draft) { create(:draft, account: account, blog: blog, author: user) }
    let!(:other_draft) { create(:draft, account: account, blog: blog, author: draft_author) }
    let!(:draft_in_other_account) { create(:draft) }

    context "for an author" do
      it "returns only the author's own drafts" do
        scope = described_class::Scope.new(AuthorizationContext.new(user: user, account: account), Draft.all)
        expect(scope.resolve).to(include(own_draft))
        expect(scope.resolve).not_to(include(other_draft))
        expect(scope.resolve).not_to(include(draft_in_other_account))
      end
    end # <--- Added this 'end'

    context "for an editor" do
      let!(:membership) { create(:account_membership, user: user, account: account, role: :editor) }

      it "returns all drafts in the account" do
        scope = described_class::Scope.new(AuthorizationContext.new(user: user, account: account), Draft.all)
        expect(scope.resolve).to(include(own_draft, other_draft))
        expect(scope.resolve).not_to(include(draft_in_other_account))
      end
    end
  end
end
