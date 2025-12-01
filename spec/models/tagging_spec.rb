# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Tagging, type: :model) do
  describe "validations" do
    subject { create(:tagging) }

    it "validates uniqueness of tag_id within scope" do
      existing = create(:tagging)
      duplicate = build(:tagging, tag: existing.tag, taggable: existing.taggable, account: existing.account)
      expect(duplicate).not_to(be_valid)
      expect(duplicate.errors[:tag_id]).to(include("has already been applied to this item"))
    end
  end

  describe "associations" do
    it { is_expected.to(belong_to(:account)) }
    it { is_expected.to(belong_to(:tag)) }
    it { is_expected.to(belong_to(:taggable)) }
  end

  describe "scopes" do
    let(:account) { create(:account) }
    let(:tag) { create(:tag, account: account) }
    let(:blog) { create(:blog, account: account) }
    let(:author) { create(:user) }

    describe ".for_posts" do
      let(:post) { create(:post, account: account, blog: blog, author: author) }
      let(:draft) { create(:draft, account: account, blog: blog, author: author) }
      let!(:post_tagging) { create(:tagging, tag: tag, taggable: post, account: account) }
      let!(:draft_tagging) { create(:tagging, tag: tag, taggable: draft, account: account) }

      it "returns only taggings for posts" do
        expect(described_class.for_posts).to(include(post_tagging))
        expect(described_class.for_posts).not_to(include(draft_tagging))
      end
    end

    describe ".for_drafts" do
      let(:post) { create(:post, account: account, blog: blog, author: author) }
      let(:draft) { create(:draft, account: account, blog: blog, author: author) }
      let!(:post_tagging) { create(:tagging, tag: tag, taggable: post, account: account) }
      let!(:draft_tagging) { create(:tagging, tag: tag, taggable: draft, account: account) }

      it "returns only taggings for drafts" do
        expect(described_class.for_drafts).to(include(draft_tagging))
        expect(described_class.for_drafts).not_to(include(post_tagging))
      end
    end
  end
end
