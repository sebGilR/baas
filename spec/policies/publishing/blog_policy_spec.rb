# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Publishing::BlogPolicy, type: :policy) do
  let(:account) { create(:account) }
  let(:blog) { create(:blog, account: account) }

  subject { described_class }

  context "for an owner" do
    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :owner) }

    permissions :index? do
      it "grants access" do
        expect(subject).to(permit(user, blog))
      end
    end

    permissions :show? do
      it "grants access to blogs in the same account" do
        expect(subject).to(permit(user, blog))
      end
    end

    permissions :create? do
      it "grants access" do
        expect(subject).to(permit(user, Blog))
      end
    end

    permissions :update? do
      it "grants access" do
        expect(subject).to(permit(user, blog))
      end
    end

    permissions :destroy? do
      it "grants access" do
        expect(subject).to(permit(user, blog))
      end
    end
  end

  context "for an admin" do
    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :admin) }

    permissions :destroy? do
      it "grants access" do
        expect(subject).to(permit(user, blog))
      end
    end
  end

  context "for an editor" do
    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :editor) }

    permissions :create?, :update? do
      it "grants access" do
        expect(subject).to(permit(user, blog))
      end
    end

    permissions :destroy? do
      it "denies access" do
        expect(subject).not_to(permit(user, blog))
      end
    end
  end

  context "for an author" do
    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :author) }

    permissions :index?, :show? do
      it "grants access" do
        expect(subject).to(permit(user, blog))
      end
    end

    permissions :create?, :update?, :destroy? do
      it "denies access" do
        expect(subject).not_to(permit(user, blog))
      end
    end
  end

  context "for a user without membership" do
    let(:user) { create(:user) }

    permissions :create?, :update?, :destroy? do
      it "denies access" do
        expect(subject).not_to(permit(user, blog))
      end
    end
  end

  describe "Scope" do
    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :owner) }
    let!(:blog_in_account) { create(:blog, account: account) }
    let!(:blog_in_other_account) { create(:blog) }

    it "returns only blogs in the user's account" do
      # Note: Pundit scopes need context with account, this test may need adjustment
      # based on how the scope is called with AuthorizationContext
      scope = described_class::Scope.new(user, Blog.all, AuthorizationContext.new(user: user, account: account))
      expect(scope.resolve).to(include(blog_in_account))
      expect(scope.resolve).not_to(include(blog_in_other_account))
    end
  end
end
