# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Post, type: :model) do
  describe "validations" do
    subject { create(:post) }

    it { is_expected.to(validate_presence_of(:title)) }
    it { is_expected.to(validate_length_of(:title).is_at_least(1).is_at_most(255)) }
    it { is_expected.to(validate_presence_of(:slug)) }
    it { is_expected.to(validate_uniqueness_of(:slug).scoped_to(:account_id).with_message("has already been taken for this account")) }
    it { is_expected.to(allow_value("test-post-1").for(:slug)) }
    it { is_expected.not_to(allow_value("Test Post").for(:slug)) }
  end

  describe "associations" do
    it { is_expected.to(belong_to(:account)) }
    it { is_expected.to(belong_to(:blog)) }
    it { is_expected.to(belong_to(:author).class_name("User")) }
    it { is_expected.to(belong_to(:category).optional) }
    it { is_expected.to(have_many(:revisions).dependent(:destroy)) }
    it { is_expected.to(have_many(:taggings).dependent(:destroy)) }
    it { is_expected.to(have_many(:tags).through(:taggings)) }
  end

  describe "enums" do
    it {
      is_expected.to(define_enum_for(:status)
        .with_values(draft: 0, published: 1, scheduled: 2, archived: 3)
        .with_prefix)
    }
  end

  describe "callbacks" do
    let(:account) { create(:account) }
    let(:blog) { create(:blog, account: account) }
    let(:author) { create(:user) }

    context "when slug is generated" do
      it "generates a slug from the title before creation" do
        post = build(:post, account: account, blog: blog, author: author, title: "My First Post", slug: nil)
        post.valid?
        expect(post.slug).to(eq("my-first-post"))
      end

      it "does not generate a slug if one is already present" do
        post = build(:post, account: account, blog: blog, author: author, title: "My First Post", slug: "custom-slug")
        post.valid?
        expect(post.slug).to(eq("custom-slug"))
      end
    end

    context "when reading time is calculated" do
      it "calculates reading time from content" do
        # 200 words should equal 1 minute reading time
        content = "word " * 200
        post = create(:post, account: account, blog: blog, author: author, content: content)
        expect(post.reading_time_minutes).to(eq(1))
      end

      it "rounds up reading time" do
        # 250 words should equal 2 minutes (rounding up from 1.25)
        content = "word " * 250
        post = create(:post, account: account, blog: blog, author: author, content: content)
        expect(post.reading_time_minutes).to(eq(2))
      end
    end

    context "when excerpt is set" do
      it "auto-generates excerpt from content if not provided" do
        content = "This is a test content. " * 20
        post = create(:post, account: account, blog: blog, author: author, content: content, excerpt: nil)
        expect(post.excerpt).to(be_present)
        expect(post.excerpt.length).to(be <= 160)
      end

      it "does not override existing excerpt" do
        post = create(:post, account: account, blog: blog, author: author, excerpt: "Custom excerpt")
        expect(post.excerpt).to(eq("Custom excerpt"))
      end
    end
  end

  describe "scopes" do
    let(:account) { create(:account) }
    let(:blog) { create(:blog, account: account) }
    let(:author) { create(:user) }

    describe ".published" do
      let!(:published_post) { create(:post, :published, blog: blog, account: account, author: author) }
      let!(:draft_post) { create(:post, blog: blog, account: account, author: author) }

      it "returns only published posts with past published_at" do
        expect(described_class.published).to(include(published_post))
        expect(described_class.published).not_to(include(draft_post))
      end
    end

    describe ".scheduled" do
      let!(:scheduled_post) { create(:post, :scheduled, blog: blog, account: account, author: author) }
      let!(:draft_post) { create(:post, blog: blog, account: account, author: author) }

      it "returns only scheduled posts with future scheduled_for" do
        expect(described_class.scheduled).to(include(scheduled_post))
        expect(described_class.scheduled).not_to(include(draft_post))
      end
    end

    describe ".featured" do
      let!(:featured_post) { create(:post, :featured, blog: blog, account: account, author: author) }
      let!(:regular_post) { create(:post, blog: blog, account: account, author: author) }

      it "returns only featured posts" do
        expect(described_class.featured).to(include(featured_post))
        expect(described_class.featured).not_to(include(regular_post))
      end
    end

    describe ".by_blog" do
      let(:other_blog) { create(:blog, account: account) }
      let!(:matching_post) { create(:post, blog: blog, account: account, author: author) }
      let!(:other_post) { create(:post, blog: other_blog, account: account, author: author) }

      it "filters by blog public_id" do
        results = described_class.by_blog(blog.public_id)
        expect(results).to(include(matching_post))
        expect(results).not_to(include(other_post))
      end

      it "filters by numeric blog_id" do
        results = described_class.by_blog(blog.id)
        expect(results).to(include(matching_post))
        expect(results).not_to(include(other_post))
      end
    end
  end

  describe "instance methods" do
    let(:account) { create(:account) }
    let(:blog) { create(:blog, account: account) }
    let(:author) { create(:user) }

    describe "#publish!" do
      let(:post) { create(:post, account: account, blog: blog, author: author, content: "Test content") }

      it "sets status to published and sets published_at" do
        expect(post.publish!).to(be(true))
        expect(post.status).to(eq("published"))
        expect(post.published_at).to(be_present)
      end
    end

    describe "#unpublish!" do
      let(:post) { create(:post, :published, account: account, blog: blog, author: author) }

      it "sets status back to draft and clears published_at" do
        post.unpublish!
        expect(post.status).to(eq("draft"))
        expect(post.published_at).to(be_nil)
      end
    end

    describe "#can_publish?" do
      it "returns true when title and content are present" do
        post = build(:post, title: "Test", content: "Content")
        expect(post.can_publish?).to(be(true))
      end

      it "returns false when content is missing" do
        post = build(:post, title: "Test", content: nil)
        expect(post.can_publish?).to(be(false))
      end
    end

    describe "#create_revision!" do
      let(:post) { create(:post, account: account, blog: blog, author: author) }

      it "creates a revision with the current content" do
        expect { post.create_revision!(author) }.to(change(Revision, :count).by(1))

        revision = post.revisions.last
        expect(revision.title).to(eq(post.title))
        expect(revision.content).to(eq(post.content))
        expect(revision.created_by).to(eq(author))
      end
    end
  end
end
