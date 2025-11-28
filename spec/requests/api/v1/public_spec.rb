# frozen_string_literal: true

require "rails_helper"

RSpec.describe("Api::V1::Public", type: :request) do
  describe "GET /api/v1/public" do
    it "returns a successful response" do
      get "/api/v1/public"
      expect(response).to(have_http_status(:ok))
    end
  end
end
