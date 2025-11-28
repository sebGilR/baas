# frozen_string_literal: true

module Api
  module V1
    module Auth
      class RegistrationsController < BaseController
        def create
          result = Core::Authentication::RegisterService.call(
            email: registration_params[:email],
            password: registration_params[:password],
            name: registration_params[:name],
            account_name: registration_params[:account_name]
          )

          if result.success?
            render json: {
              data: {
                type: 'authentication',
                attributes: {
                  user: UserSerializer.new(result.data.user).serializable_hash[:data][:attributes],
                  account: AccountSerializer.new(result.data.account).serializable_hash[:data][:attributes],
                  access_token: result.data.access_token,
                  refresh_token: result.data.refresh_token,
                  token_type: 'Bearer',
                  expires_in: result.data.expires_in
                }
              }
            }, status: :created
          else
            render json: {
              errors: [{
                status: '422',
                title: 'Registration Failed',
                detail: result.errors
              }]
            }, status: :unprocessable_entity
          end
        end

        private

        def registration_params
          params.require(:data).require(:attributes).permit(:email, :password, :name, :account_name)
        end
      end
    end
  end
end
