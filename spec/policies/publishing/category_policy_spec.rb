# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Publishing::CategoryPolicy, type: :policy) do
  let(:account) { create(:account) }
  let(:category) { create(:category, account: account) }

  subject { described_class }

  context "for an owner" do
    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :owner) }

    permissions :index?, :show?, :create?, :update?, :destroy? do
      it "grants access" do
        expect(subject).to(permit(user, category))
      end
    end
  end

  context "for an admin" do
    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :admin) }

    permissions :destroy? do
      it "grants access" do
        expect(subject).to(permit(user, category))
      end
    end
  end

  context "for an editor" do
    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :editor) }

    permissions :index?, :show?, :create?, :update? do
      it "grants access" do
        expect(subject).to(permit(user, category))
      end
    end

    permissions :destroy? do
      it "denies access" do
        expect(subject).not_to(permit(user, category))
      end
    end
  end

  context "for an author" do
    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :author) }

    permissions :index?, :show? do
      it "grants access" do
        expect(subject).to(permit(user, category))
      end
    end

    permissions :create?, :update?, :destroy? do
      it "denies access" do
        expect(subject).not_to(permit(user, category))
      end
    end
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
