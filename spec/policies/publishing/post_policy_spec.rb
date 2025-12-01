# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Publishing::PostPolicy, type: :policy) do
  let(:account) { create(:account) }
  let(:blog) { create(:blog, account: account) }
  let(:author) { create(:user) }
  let(:post) { create(:post, account: account, blog: blog, author: author) }

  subject { described_class }

  context "for an owner" do
    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :owner) }

    permissions :index?, :show?, :create?, :update?, :destroy?, :publish?, :unpublish? do
      it "grants access" do
        expect(subject).to(permit(user, post))
      end
    end
  end

  context "for an editor" do
    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :editor) }

    permissions :index?, :show?, :create?, :update?, :publish?, :unpublish? do
      it "grants access" do
        expect(subject).to(permit(user, post))
      end
    end

    permissions :destroy? do
      it "grants access" do
        expect(subject).to(permit(user, post))
      end
    end
  end

  context "for an author" do
    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :author) }

    permissions :index?, :show?, :create? do
      it "grants access" do
        expect(subject).to(permit(user, post))
      end
    end

    context "for their own posts" do
      let(:post) { create(:post, account: account, blog: blog, author: user) }

      permissions :update? do
        it "grants access" do
          expect(subject).to(permit(user, post))
        end
      end

      context "when post is a draft" do
        let(:post) { create(:post, account: account, blog: blog, author: user, status: :draft) }

        permissions :destroy? do
          it "grants access" do
            expect(subject).to(permit(user, post))
          end
        end
      end

      context "when post is published" do
        let(:post) { create(:post, :published, account: account, blog: blog, author: user) }

        permissions :destroy? do
          it "denies access" do
            expect(subject).not_to(permit(user, post))
          end
        end
      end
    end

    context "for other authors' posts" do
      permissions :update?, :destroy? do
        it "denies access" do
          expect(subject).not_to(permit(user, post))
        end
      end
    end

    permissions :publish?, :unpublish? do
      it "denies access" do
        expect(subject).not_to(permit(user, post))
      end
    end
  end

  describe "Scope" do
    let(:user) { create(:user) }
    let!(:membership) { create(:account_membership, user: user, account: account, role: :owner) }
    let!(:post_in_account) { create(:post, account: account, blog: blog, author: author) }
    let!(:post_in_other_account) { create(:post) }

    it "returns only posts in the user's account" do
      scope = described_class::Scope.new(user, Post.all, AuthorizationContext.new(user: user, account: account))
      expect(scope.resolve).to(include(post_in_account))
      expect(scope.resolve).not_to(include(post_in_other_account))
    end
  end
end
