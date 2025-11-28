# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Auth::Sessions', type: :request do
  describe 'POST /api/v1/auth/login' do
    let(:user) { create(:user, password: 'Password123!') }
    let!(:account) { create(:account) }
    let!(:membership) { create(:account_membership, user: user, account: account) }

    context 'with valid credentials' do
      let(:valid_credentials) do
        {
          data: {
            type: 'authentication',
            attributes: {
              email: user.email,
              password: 'Password123!'
            }
          }
        }
      end

      it 'returns a successful response with tokens' do
        post '/api/v1/auth/login', params: valid_credentials, as: :json
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['data']['attributes']['access_token']).to be_present
        expect(json_response['data']['attributes']['refresh_token']).to be_present
      end
    end

    context 'with invalid credentials' do
      let(:invalid_credentials) do
        {
          data: {
            type: 'authentication',
            attributes: {
              email: user.email,
              password: 'wrong-password'
            }
          }
        }
      end

      it 'returns an unauthorized response' do
        post '/api/v1/auth/login', params: invalid_credentials, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
