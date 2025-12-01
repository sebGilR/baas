# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Blog, type: :model) do
  describe "validations" do
    subject { create(:blog) }

    it { is_expected.to(validate_presence_of(:name)) }
    it { is_expected.to(validate_length_of(:name).is_at_least(2).is_at_most(100)) }
    it { is_expected.to(validate_presence_of(:slug)) }
    it { is_expected.to(validate_uniqueness_of(:slug).scoped_to(:account_id).with_message("has already been taken for this account")) }
    it { is_expected.to(allow_value("test-blog-1").for(:slug)) }
    it { is_expected.not_to(allow_value("Test Blog").for(:slug)) }
  end

  describe "associations" do
    it { is_expected.to(belong_to(:account)) }
    it { is_expected.to(have_many(:posts).dependent(:destroy)) }
    it { is_expected.to(have_many(:drafts).dependent(:destroy)) }
  end

  describe "enums" do
    it { is_expected.to(define_enum_for(:status).with_values(active: 0, archived: 1, deleted: 2).with_prefix) }
  end

  describe "callbacks" do
    context "when slug is generated" do
      it "generates a slug from the name before creation" do
        account = create(:account)
        blog = build(:blog, account: account, name: "My Tech Blog", slug: nil)
        blog.valid?
        expect(blog.slug).to(eq("my-tech-blog"))
      end

      it "does not generate a slug if one is already present" do
        account = create(:account)
        blog = build(:blog, account: account, name: "My Tech Blog", slug: "custom-slug")
        blog.valid?
        expect(blog.slug).to(eq("custom-slug"))
      end

      it "generates a unique slug within account scope" do
        account = create(:account)
        create(:blog, account: account, name: "My Tech Blog", slug: "my-tech-blog")
        blog = build(:blog, account: account, name: "My Tech Blog", slug: nil)
        blog.valid?
        expect(blog.slug).to(eq("my-tech-blog-1"))
      end
    end
  end

  describe "scopes" do
    let(:account) { create(:account) }
    let!(:active_blog) { create(:blog, account: account, status: :active) }
    let!(:archived_blog) { create(:blog, account: account, status: :archived) }

    describe ".active" do
      it "returns only active blogs" do
        expect(described_class.active).to(include(active_blog))
        expect(described_class.active).not_to(include(archived_blog))
      end
    end

    describe ".ordered" do
      let!(:older_blog) { create(:blog, account: account, created_at: 1.day.ago) }
      let!(:newer_blog) { create(:blog, account: account, created_at: Time.current) }

      it "returns blogs ordered by created_at desc" do
        expect(described_class.ordered.first).to(eq(newer_blog))
      end
    end
  end

  describe "instance methods" do
    let(:account) { create(:account) }
    let(:blog) { create(:blog, account: account) }

    describe "#published_posts" do
      let(:author) { create(:user) }
      let!(:published_post) { create(:post, :published, blog: blog, account: account, author: author) }
      let!(:draft_post) { create(:post, blog: blog, account: account, author: author, status: :draft) }

      it "returns only published posts" do
        expect(blog.published_posts).to(include(published_post))
        expect(blog.published_posts).not_to(include(draft_post))
      end
    end

    describe "#post_count" do
      let(:author) { create(:user) }

      before do
        create_list(:post, 3, blog: blog, account: account, author: author)
      end

      it "returns the count of posts" do
        expect(blog.post_count).to(eq(3))
      end
    end
  end
end
