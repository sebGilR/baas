# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Tag, type: :model) do
  describe "validations" do
    subject { create(:tag) }

    it { is_expected.to(validate_presence_of(:name)) }
    it { is_expected.to(validate_length_of(:name).is_at_least(1).is_at_most(50)) }
    it { is_expected.to(validate_uniqueness_of(:name).scoped_to(:account_id).case_insensitive) }
    it { is_expected.to(validate_presence_of(:slug)) }
    it { is_expected.to(validate_uniqueness_of(:slug).scoped_to(:account_id)) }
    it { is_expected.to(allow_value("test-tag-1").for(:slug)) }
    it { is_expected.not_to(allow_value("Test Tag").for(:slug)) }
    it { is_expected.to(allow_value("#FF5733").for(:color)) }
    it { is_expected.not_to(allow_value("invalid-color").for(:color)) }
    it { is_expected.to(allow_value(nil).for(:color)) }
  end

  describe "associations" do
    it { is_expected.to(belong_to(:account)) }
    it { is_expected.to(have_many(:taggings).dependent(:destroy)) }
    it { is_expected.to(have_many(:posts).through(:taggings)) }
    it { is_expected.to(have_many(:drafts).through(:taggings)) }
  end

  describe "callbacks" do
    let(:account) { create(:account) }

    context "when slug is generated" do
      it "generates a slug from the name before creation" do
        tag = build(:tag, account: account, name: "Ruby on Rails", slug: nil)
        tag.valid?
        expect(tag.slug).to(eq("ruby-on-rails"))
      end
    end

    context "when name is normalized" do
      it "downcases and strips the name" do
        tag = build(:tag, account: account, name: "  RAILS  ")
        tag.valid?
        expect(tag.name).to(eq("rails"))
      end
    end
  end

  describe "scopes" do
    let(:account) { create(:account) }

    describe ".ordered" do
      let!(:tag_b) { create(:tag, account: account, name: "beta") }
      let!(:tag_a) { create(:tag, account: account, name: "alpha") }

      it "returns tags ordered alphabetically by name" do
        expect(described_class.ordered.first).to(eq(tag_a))
      end
    end

    describe ".popular" do
      let!(:popular_tag) { create(:tag, account: account) }
      let!(:unpopular_tag) { create(:tag, account: account) }
      let(:blog) { create(:blog, account: account) }
      let(:author) { create(:user) }

      before do
        posts = create_list(:post, 3, account: account, blog: blog, author: author)
        posts.each do |post|
          create(:tagging, tag: popular_tag, taggable: post, account: account)
        end
      end

      it "returns tags ordered by usage count" do
        expect(described_class.popular.first).to(eq(popular_tag))
      end
    end
  end

  describe "instance methods" do
    let(:account) { create(:account) }
    let(:tag) { create(:tag, account: account) }
    let(:blog) { create(:blog, account: account) }
    let(:author) { create(:user) }

    describe "#post_count" do
      before do
        posts = create_list(:post, 2, account: account, blog: blog, author: author)
        posts.each do |post|
          create(:tagging, tag: tag, taggable: post, account: account)
        end
      end

      it "returns the count of posts with this tag" do
        expect(tag.post_count).to(eq(2))
      end
    end

    describe "#usage_count" do
      before do
        post = create(:post, account: account, blog: blog, author: author)
        draft = create(:draft, account: account, blog: blog, author: author)
        create(:tagging, tag: tag, taggable: post, account: account)
        create(:tagging, tag: tag, taggable: draft, account: account)
      end

      it "returns the total count of taggings" do
        expect(tag.usage_count).to(eq(2))
      end
    end
  end
end
