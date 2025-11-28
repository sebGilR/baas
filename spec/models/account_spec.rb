# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Account, type: :model) do
  describe "validations" do
    subject { create(:account) }

    it { is_expected.to(validate_presence_of(:name)) }
    it { is_expected.to(validate_length_of(:name).is_at_least(2)) }
    it { is_expected.to(validate_uniqueness_of(:slug)) }
    it { is_expected.to(allow_value("test-slug-1").for(:slug)) }
    it { is_expected.not_to(allow_value("Test Slug").for(:slug)) }
  end

  describe "associations" do
    it { is_expected.to(have_many(:account_memberships).dependent(:destroy)) }
    it { is_expected.to(have_many(:users).through(:account_memberships)) }
  end

  describe "enums" do
    it { is_expected.to(define_enum_for(:status).with_values(active: 0, suspended: 1, deleted: 2).with_prefix) }
    it { is_expected.to(define_enum_for(:plan).with_values(free: 0, pro: 1, team: 2).with_prefix) }
  end

  describe "callbacks" do
    context "when slug is generated" do
      it "generates a slug from the name before creation" do
        account = build(:account, name: "Test Account", slug: nil)
        account.valid?
        expect(account.slug).to(eq("test-account"))
      end

      it "does not generate a slug if one is already present" do
        account = build(:account, name: "Test Account", slug: "custom-slug")
        account.valid?
        expect(account.slug).to(eq("custom-slug"))
      end

      it "generates a unique slug if the parameterized name already exists" do
        create(:account, name: "Test Account")
        account = build(:account, name: "Test Account", slug: nil)
        account.valid?
        expect(account.slug).to(eq("test-account-1"))
      end
    end
  end

  describe "scopes" do
    let!(:active_account) { create(:account, status: :active) }
    let!(:suspended_account) { create(:account, status: :suspended) }

    it "returns only active accounts" do
      expect(described_class.active).to(include(active_account))
      expect(described_class.active).not_to(include(suspended_account))
    end
  end
end
