# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Api::V1::AuthenticationSerializer) do
  let(:user) { create(:user) }
  let(:account) { create(:account) }
  let(:access_token) { "access_token_string" }
  let(:refresh_token) { "refresh_token_string" }
  let(:expires_in) { 3600 }

  let(:serializer) do
    described_class.new(
      user: user,
      account: account,
      access_token: access_token,
      refresh_token: refresh_token,
      expires_in: expires_in,
    )
  end

  let(:hash) { serializer.serializable_hash }
  let(:attributes) { hash[:data][:attributes] }

  before do
    # Mocking the dependency serializers to return full data objects
    allow(Api::V1::UserSerializer).to(receive(:new).with(user).and_return(
      double(serializable_hash: { data: { id: user.public_id, type: "user", attributes: { name: user.name, email: user.email } } }),
    ))
    allow(Api::V1::AccountSerializer).to(receive(:new).with(account).and_return(
      double(serializable_hash: { data: { id: account.public_id, type: "account", attributes: { name: account.name } } }),
    ))
  end

  it "creates a JSON:API compliant hash" do
    expect(hash[:data][:type]).to(eq("authentication"))
  end

  it "includes the correct token information" do
    expect(attributes[:access_token]).to(eq(access_token))
    expect(attributes[:refresh_token]).to(eq(refresh_token))
    expect(attributes[:token_type]).to(eq("Bearer"))
    expect(attributes[:expires_in]).to(eq(expires_in))
  end

  it "includes the serialized user data object" do
    # Trigger serialization
    attributes
    expect(Api::V1::UserSerializer).to(have_received(:new).with(user))
    expect(attributes[:user][:type]).to(eq("user"))
    expect(attributes[:user][:attributes][:name]).to(eq(user.name))
  end

  it "includes the serialized account data object" do
    # Trigger serialization
    attributes
    expect(Api::V1::AccountSerializer).to(have_received(:new).with(account))
    expect(attributes[:account][:type]).to(eq("account"))
    expect(attributes[:account][:attributes][:name]).to(eq(account.name))
  end
end
