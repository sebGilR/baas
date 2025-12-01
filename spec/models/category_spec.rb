# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Category, type: :model) do
  describe "validations" do
    subject { create(:category) }

    it { is_expected.to(validate_presence_of(:name)) }
    it { is_expected.to(validate_length_of(:name).is_at_least(1).is_at_most(100)) }
    it { is_expected.to(validate_uniqueness_of(:name).scoped_to(:account_id).case_insensitive) }
    it { is_expected.to(validate_presence_of(:slug)) }
    it { is_expected.to(validate_uniqueness_of(:slug).scoped_to(:account_id)) }
    it { is_expected.to(allow_value("test-category-1").for(:slug)) }
    it { is_expected.not_to(allow_value("Test Category").for(:slug)) }
  end

  describe "associations" do
    it { is_expected.to(belong_to(:account)) }
    it { is_expected.to(belong_to(:parent).class_name("Category").optional) }
    it { is_expected.to(have_many(:children).class_name("Category").with_foreign_key(:parent_id).dependent(:nullify)) }
    it { is_expected.to(have_many(:posts)) }
  end

  describe "custom validations" do
    let(:account) { create(:account) }

    context "when parent is self" do
      it "is invalid" do
        category = create(:category, account: account)
        category.parent = category
        expect(category).not_to(be_valid)
        expect(category.errors[:parent_id]).to(include("cannot be the category itself"))
      end
    end

    context "when parent creates a cycle" do
      it "is invalid" do
        parent = create(:category, account: account)
        child = create(:category, account: account, parent: parent)
        parent.parent = child
        expect(parent).not_to(be_valid)
        expect(parent.errors[:parent_id]).to(include("cannot create a circular reference"))
      end
    end
  end

  describe "callbacks" do
    let(:account) { create(:account) }

    context "when slug is generated" do
      it "generates a slug from the name before creation" do
        category = build(:category, account: account, name: "Technology", slug: nil)
        category.valid?
        expect(category.slug).to(eq("technology"))
      end
    end
  end

  describe "scopes" do
    let(:account) { create(:account) }

    describe ".roots" do
      let!(:root_category) { create(:category, account: account, parent: nil) }
      let!(:child_category) { create(:category, account: account, parent: root_category) }

      it "returns only root categories" do
        expect(described_class.roots).to(include(root_category))
        expect(described_class.roots).not_to(include(child_category))
      end
    end

    describe ".ordered" do
      let!(:category_b) { create(:category, account: account, name: "Beta", position: 1) }
      let!(:category_a) { create(:category, account: account, name: "Alpha", position: 0) }

      it "returns categories ordered by position and name" do
        expect(described_class.ordered.first).to(eq(category_a))
      end
    end
  end

  describe "instance methods" do
    let(:account) { create(:account) }

    describe "#root?" do
      it "returns true if parent_id is nil" do
        category = build(:category, parent: nil)
        expect(category.root?).to(be(true))
      end

      it "returns false if parent_id is present" do
        parent = create(:category, account: account)
        category = build(:category, parent: parent)
        expect(category.root?).to(be(false))
      end
    end

    describe "#leaf?" do
      it "returns true if category has no children" do
        category = create(:category, account: account)
        expect(category.leaf?).to(be(true))
      end

      it "returns false if category has children" do
        parent = create(:category, account: account)
        create(:category, account: account, parent: parent)
        expect(parent.leaf?).to(be(false))
      end
    end

    describe "#ancestors" do
      let(:grandparent) { create(:category, account: account, name: "Grandparent") }
      let(:parent) { create(:category, account: account, name: "Parent", parent: grandparent) }
      let(:child) { create(:category, account: account, name: "Child", parent: parent) }

      it "returns all ancestor categories" do
        expect(child.ancestors).to(eq([grandparent, parent]))
      end
    end

    describe "#descendants" do
      let(:parent) { create(:category, account: account) }
      let!(:child1) { create(:category, account: account, parent: parent) }
      let!(:child2) { create(:category, account: account, parent: parent) }

      it "returns all descendant categories" do
        expect(parent.descendants).to(include(child1, child2))
      end
    end

    describe "#depth" do
      let(:grandparent) { create(:category, account: account) }
      let(:parent) { create(:category, account: account, parent: grandparent) }
      let(:child) { create(:category, account: account, parent: parent) }

      it "returns the depth of the category" do
        expect(grandparent.depth).to(eq(0))
        expect(parent.depth).to(eq(1))
        expect(child.depth).to(eq(2))
      end
    end

    describe "#full_path" do
      let(:grandparent) { create(:category, account: account, name: "Tech") }
      let(:parent) { create(:category, account: account, name: "Programming", parent: grandparent) }
      let(:child) { create(:category, account: account, name: "Ruby", parent: parent) }

      it "returns the full path of the category" do
        expect(child.full_path).to(eq("Tech > Programming > Ruby"))
      end
    end

    describe "#post_count" do
      let(:category) { create(:category, account: account) }
      let(:blog) { create(:blog, account: account) }
      let(:author) { create(:user) }

      before do
        create_list(:post, 2, account: account, blog: blog, author: author, category: category)
      end

      it "returns the count of posts in this category" do
        expect(category.post_count).to(eq(2))
      end
    end
  end
end
