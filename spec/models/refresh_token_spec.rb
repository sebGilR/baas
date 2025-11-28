# frozen_string_literal: true

require "rails_helper"

RSpec.describe(RefreshToken, type: :model) do
  describe "validations" do
    subject { create(:refresh_token, user: user) }

    let(:user) { create(:user) }

    it { is_expected.to(validate_presence_of(:jti)) }
    it { is_expected.to(validate_uniqueness_of(:jti)) }
    it { is_expected.to(validate_presence_of(:token_digest)) }
    it { is_expected.to(validate_presence_of(:expires_at)) }
  end

  describe "associations" do
    it { is_expected.to(belong_to(:user)) }
  end

  describe "scopes" do
    let(:user) { create(:user) }
    let!(:active_token) { create(:refresh_token, user: user) }
    let!(:expired_token) { create(:refresh_token, user: user, expires_at: 1.day.ago) }
    let!(:revoked_token) { create(:refresh_token, user: user, revoked_at: Time.current) }

    it ".active" do
      expect(described_class.active).to(include(active_token))
      expect(described_class.active).not_to(include(expired_token))
      expect(described_class.active).not_to(include(revoked_token))
    end

    it ".expired" do
      expect(described_class.expired).to(include(expired_token))
      expect(described_class.expired).not_to(include(active_token))
    end

    it ".revoked" do
      expect(described_class.revoked).to(include(revoked_token))
      expect(described_class.revoked).not_to(include(active_token))
    end
  end

  describe "instance methods" do
    let(:user) { create(:user) }

    it "#expired?" do
      expect(build(:refresh_token, user: user, expires_at: 1.day.from_now).expired?).to(be(false))
      expect(build(:refresh_token, user: user, expires_at: 1.day.ago).expired?).to(be(true))
    end

    it "#revoked?" do
      expect(build(:refresh_token, user: user, revoked_at: nil).revoked?).to(be(false))
      expect(build(:refresh_token, user: user, revoked_at: Time.current).revoked?).to(be(true))
    end

    it "#active?" do
      expect(build(:refresh_token, user: user).active?).to(be(true))
      expect(build(:refresh_token, user: user, expires_at: 1.day.ago).active?).to(be(false))
      expect(build(:refresh_token, user: user, revoked_at: Time.current).active?).to(be(false))
    end

    it "#revoke!" do
      token = create(:refresh_token, user: user)
      expect { token.revoke! }.to(change { token.revoked_at }.from(nil))
    end

    it "#touch_last_used!" do
      token = create(:refresh_token, user: user, last_used_at: 1.day.ago)
      expect { token.touch_last_used! }.to(change { token.last_used_at })
    end
  end
end
