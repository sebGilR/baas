# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Publishing::DraftPolicy, type: :policy) do
  let(:account) { create(:account) }
  let(:blog) { create(:blog, account: account) }
  let(:draft_author) { create(:user) }
  let(:draft) { create(:draft, account: account, blog: blog, author: draft_author) }

  subject { described_class }

  context "for an owner" do
    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :owner) }

    permissions :index?, :show?, :create?, :update?, :destroy?, :autosave?, :convert_to_post? do
      it "grants access" do
        expect(subject).to(permit(user, draft))
      end
    end
  end

  context "for an editor" do
    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :editor) }

    permissions :index?, :show?, :create?, :update?, :destroy?, :autosave?, :convert_to_post? do
      it "grants access to any draft in the account" do
        expect(subject).to(permit(user, draft))
      end
    end
  end

  context "for an author" do
    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :author) }

    permissions :index?, :create? do
      it "grants access" do
        expect(subject).to(permit(user, draft))
      end
    end

    context "for their own drafts" do
      let(:draft) { create(:draft, account: account, blog: blog, author: user) }

      permissions :show?, :update?, :destroy?, :autosave?, :convert_to_post? do
        it "grants access" do
          expect(subject).to(permit(user, draft))
        end
      end
    end

    context "for other authors' drafts" do
      permissions :show?, :update?, :destroy?, :autosave?, :convert_to_post? do
        it "denies access" do
          expect(subject).not_to(permit(user, draft))
        end
      end
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
        scope = described_class::Scope.new(user, Draft.all, AuthorizationContext.new(user: user, account: account))
        expect(scope.resolve).to(include(own_draft))
        expect(scope.resolve).not_to(include(other_draft))
        expect(scope.resolve).not_to(include(draft_in_other_account))
      end
    end

    context "for an editor" do
      let!(:membership) { create(:account_membership, user: user, account: account, role: :editor) }

      it "returns all drafts in the account" do
        scope = described_class::Scope.new(user, Draft.all, AuthorizationContext.new(user: user, account: account))
        expect(scope.resolve).to(include(own_draft, other_draft))
        expect(scope.resolve).not_to(include(draft_in_other_account))
      end
    end
  end
end
