# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Auth::Registrations', type: :request do
  describe 'POST /api/v1/auth/register' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          data: {
            type: 'authentication',
            attributes: {
              email: 'test@example.com',
              password: 'Password123!',
              name: 'Test User',
              account_name: 'Test Account'
            }
          }
        }
      end

      it 'creates a new user, account, and membership' do
        expect do
          post '/api/v1/auth/register', params: valid_params, as: :json
        end.to change(User, :count).by(1)
          .and change(Account, :count).by(1)
          .and change(AccountMembership, :count).by(1)
      end

      it 'returns a successful response with tokens' do
        post '/api/v1/auth/register', params: valid_params, as: :json
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['data']['attributes']['access_token']).to be_present
        expect(json_response['data']['attributes']['refresh_token']).to be_present
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          data: {
            type: 'authentication',
            attributes: {
              email: 'invalid-email',
              password: 'short',
              name: '',
              account_name: ''
            }
          }
        }
      end

      it 'does not create a new user' do
        expect do
          post '/api/v1/auth/register', params: invalid_params, as: :json
        end.not_to change(User, :count)
      end

      it 'returns an unprocessable entity response' do
        post '/api/v1/auth/register', params: invalid_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
