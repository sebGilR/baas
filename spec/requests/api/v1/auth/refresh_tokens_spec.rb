# frozen_string_literal: true

require "rails_helper"

RSpec.describe("Api::V1::Auth::RefreshTokens", type: :request) do
  let(:user) { create(:user) }
  let!(:account) { create(:account) }
  let!(:membership) { create(:account_membership, user: user, account: account) }
  let(:raw_refresh_token) { SecureRandom.urlsafe_base64(32) }
  let!(:refresh_token) do
    create(
      :refresh_token,
      user: user,
      token_digest: Digest::SHA256.hexdigest(raw_refresh_token),
    )
  end

  describe "POST /api/v1/auth/refresh" do
    context "with a valid refresh token" do
      let(:valid_params) do
        {
          data: {
            type: "authentication",
            attributes: {
              refresh_token: raw_refresh_token,
            },
          },
        }
      end

      it "returns new tokens" do
        post "/api/v1/auth/refresh", params: valid_params, as: :json
        expect(response).to(have_http_status(:ok))
        json_response = response.parsed_body
        expect(json_response["data"]["attributes"]["access_token"]).to(be_present)
        expect(json_response["data"]["attributes"]["refresh_token"]).to(be_present)
        expect(json_response["data"]["attributes"]["refresh_token"]).not_to(eq(raw_refresh_token))
      end
    end

    context "with an invalid refresh token" do
      let(:invalid_params) do
        {
          data: {
            type: "authentication",
            attributes: {
              refresh_token: "invalid-token",
            },
          },
        }
      end

      it "returns an unauthorized response" do
        post "/api/v1/auth/refresh", params: invalid_params, as: :json
        expect(response).to(have_http_status(:unauthorized))
      end
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    context "with a valid refresh token" do
      let(:valid_params) do
        {
          data: {
            type: "authentication",
            attributes: {
              refresh_token: raw_refresh_token,
            },
          },
        }
      end

      it "revokes the refresh token" do
        delete "/api/v1/auth/logout", params: valid_params, as: :json
        expect(response).to(have_http_status(:no_content))
        expect(refresh_token.reload.revoked?).to(be(true))
      end
    end

    context "with an invalid refresh token" do
      let(:invalid_params) do
        {
          data: {
            type: "authentication",
            attributes: {
              refresh_token: "invalid-token",
            },
          },
        }
      end

      it "returns a bad request response" do
        delete "/api/v1/auth/logout", params: invalid_params, as: :json
        expect(response).to(have_http_status(:bad_request))
      end
    end
  end
end
