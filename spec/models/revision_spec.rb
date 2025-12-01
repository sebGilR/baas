# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Revision, type: :model) do
  describe "validations" do
    subject { create(:revision) }

    it { is_expected.to(validate_presence_of(:title)) }
    it { is_expected.to(validate_presence_of(:revision_number)) }
    it { is_expected.to(validate_uniqueness_of(:revision_number).scoped_to([:account_id, :post_id])) }
    it { is_expected.to(validate_numericality_of(:revision_number).only_integer.is_greater_than(0)) }
  end

  describe "associations" do
    it { is_expected.to(belong_to(:account)) }
    it { is_expected.to(belong_to(:post)) }
    it { is_expected.to(belong_to(:created_by).class_name("User")) }
  end

  describe "scopes" do
    let(:account) { create(:account) }
    let(:blog) { create(:blog, account: account) }
    let(:author) { create(:user) }
    let(:post) { create(:post, account: account, blog: blog, author: author) }

    describe ".ordered" do
      let!(:revision_1) { create(:revision, account: account, post: post, created_by: author, revision_number: 1) }
      let!(:revision_2) { create(:revision, account: account, post: post, created_by: author, revision_number: 2) }

      it "returns revisions ordered by revision_number desc" do
        expect(described_class.ordered.first).to(eq(revision_2))
      end
    end

    describe ".by_post" do
      let(:other_post) { create(:post, account: account, blog: blog, author: author) }
      let!(:revision) { create(:revision, account: account, post: post, created_by: author, revision_number: 1) }
      let!(:other_revision) { create(:revision, account: account, post: other_post, created_by: author, revision_number: 1) }

      it "returns only revisions for the specified post" do
        expect(described_class.by_post(post.id)).to(include(revision))
        expect(described_class.by_post(post.id)).not_to(include(other_revision))
      end
    end
  end

  describe "instance methods" do
    let(:account) { create(:account) }
    let(:blog) { create(:blog, account: account) }
    let(:author) { create(:user) }
    let(:post) { create(:post, account: account, blog: blog, author: author, title: "Current Title", content: "Current content") }
    let(:revision) { create(:revision, account: account, post: post, created_by: author, title: "Old Title", content: "Old content", revision_number: 1) }

    describe "#restore!" do
      it "restores the post to this revision" do
        revision.restore!
        post.reload

        expect(post.title).to(eq("Old Title"))
        expect(post.content).to(eq("Old content"))
      end
    end

    describe "#diff_from_current" do
      it "returns a hash with diff information" do
        diff = revision.diff_from_current

        expect(diff[:title_changed]).to(be(true))
        expect(diff[:content_changed]).to(be(true))
        expect(diff[:current_title]).to(eq("Current Title"))
        expect(diff[:revision_title]).to(eq("Old Title"))
      end
    end

    describe "#word_count" do
      it "returns the word count of the content" do
        revision = build(:revision, content: "This is a test content")
        expect(revision.word_count).to(eq(5))
      end

      it "returns 0 if content is blank" do
        revision = build(:revision, content: nil)
        expect(revision.word_count).to(eq(0))
      end
    end
  end
end
