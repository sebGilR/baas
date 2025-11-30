# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Api::V1::TokenSerializer) do
  let(:access_token) { "access_token_string" }
  let(:refresh_token) { "refresh_token_string" }
  let(:expires_in) { 3600 }

  let(:serializer) do
    described_class.new(
      access_token: access_token,
      refresh_token: refresh_token,
      expires_in: expires_in,
    )
  end

  let(:hash) { serializer.serializable_hash }
  let(:attributes) { hash[:data][:attributes] }

  it "creates a JSON:API compliant hash" do
    expect(hash[:data][:type]).to(eq("authentication"))
  end

  it "includes the correct token information" do
    expect(attributes[:access_token]).to(eq(access_token))
    expect(attributes[:refresh_token]).to(eq(refresh_token))
    expect(attributes[:token_type]).to(eq("Bearer"))
    expect(attributes[:expires_in]).to(eq(expires_in))
  end

  it "does not include user or account information" do
    expect(attributes).not_to(have_key(:user))
    expect(attributes).not_to(have_key(:account))
  end
end
