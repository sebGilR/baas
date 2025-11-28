# frozen_string_literal: true

RSpec.shared_context("with decoded JWT payload") do
  let(:decoded_token) do
    JWT.decode(
      token,
      Rails.application.credentials.secret_key_base || Rails.application.secret_key_base,
      true,
      { algorithm: "HS256" },
    )
  end

  let(:payload) { decoded_token.first }
end
