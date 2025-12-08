# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApiKey, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:account) }
  end

  describe "validations" do
    subject { build(:api_key) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:prefix) }
    it { is_expected.to validate_presence_of(:secret_digest) }
    it { is_expected.to validate_presence_of(:scopes) }
    it { is_expected.to validate_length_of(:name).is_at_least(2).is_at_most(100) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:environment).with_values(live: 0, test: 1).with_prefix(true) }
  end

  describe ".generate" do
    let(:user) { create(:user) }
    let(:account) { create(:account) }

    it "generates an API key with a random secret" do
      api_key, raw_token = described_class.generate(
        user: user,
        account: account,
        name: "Test Key",
        scopes: ["posts:read"]
      )

      expect(api_key).to be_a(ApiKey)
      expect(api_key.name).to eq("Test Key")
      expect(api_key.scopes).to eq(["posts:read"])
      expect(raw_token).to start_with("ak_live_")
      expect(raw_token).to include(".")
    end

    it "generates a test environment key when specified" do
      api_key, raw_token = described_class.generate(
        user: user,
        account: account,
        name: "Test Key",
        environment: :test
      )

      expect(api_key.environment_test?).to be true
      expect(raw_token).to start_with("ak_test_")
    end

    it "sets expiration when specified" do
      expires_at = 30.days.from_now
      api_key, _raw_token = described_class.generate(
        user: user,
        account: account,
        name: "Test Key",
        expires_at: expires_at
      )

      expect(api_key.expires_at).to be_within(1.second).of(expires_at)
    end
  end

  describe "#valid_secret?" do
    let(:api_key) { build(:api_key, :with_known_secret, raw_secret: "my_secret") }

    it "returns true for valid secret" do
      expect(api_key.valid_secret?("my_secret")).to be true
    end

    it "returns false for invalid secret" do
      expect(api_key.valid_secret?("wrong_secret")).to be false
    end
  end

  describe "#active?" do
    it "returns true for active key" do
      api_key = build(:api_key)
      expect(api_key.active?).to be true
    end

    it "returns false for revoked key" do
      api_key = build(:api_key, :revoked)
      expect(api_key.active?).to be false
    end

    it "returns false for expired key" do
      api_key = build(:api_key, :expired)
      expect(api_key.active?).to be false
    end
  end

  describe "#revoke!" do
    let(:api_key) { create(:api_key) }

    it "sets revoked_at timestamp" do
      expect { api_key.revoke! }.to change { api_key.revoked? }.from(false).to(true)
    end
  end

  describe "#has_scope?" do
    let(:api_key) { build(:api_key, scopes: ["posts:read", "posts:write", "admin:*"]) }

    it "returns true for exact scope match" do
      expect(api_key.has_scope?("posts:read")).to be true
    end

    it "returns false for missing scope" do
      expect(api_key.has_scope?("blogs:write")).to be false
    end

    it "matches wildcard scopes" do
      expect(api_key.has_scope?("admin:users")).to be true
      expect(api_key.has_scope?("admin:settings")).to be true
    end
  end

  describe "#has_scopes?" do
    let(:api_key) { build(:api_key, scopes: ["posts:read", "posts:write"]) }

    it "returns true when all scopes present" do
      expect(api_key.has_scopes?(["posts:read", "posts:write"])).to be true
    end

    it "returns false when any scope missing" do
      expect(api_key.has_scopes?(["posts:read", "blogs:read"])).to be false
    end
  end

  describe "#status" do
    it "returns :active for active key" do
      expect(build(:api_key).status).to eq(:active)
    end

    it "returns :revoked for revoked key" do
      expect(build(:api_key, :revoked).status).to eq(:revoked)
    end

    it "returns :expired for expired key" do
      expect(build(:api_key, :expired).status).to eq(:expired)
    end
  end

  describe "scopes" do
    let!(:active_key) { create(:api_key) }
    let!(:revoked_key) { create(:api_key, :revoked) }
    let!(:expired_key) { create(:api_key, :expired) }

    describe ".active" do
      it "returns only active keys" do
        expect(described_class.active).to contain_exactly(active_key)
      end
    end

    describe ".revoked" do
      it "returns only revoked keys" do
        expect(described_class.revoked).to contain_exactly(revoked_key)
      end
    end

    describe ".expired" do
      it "returns only expired keys" do
        expect(described_class.expired).to contain_exactly(expired_key)
      end
    end
  end
end
