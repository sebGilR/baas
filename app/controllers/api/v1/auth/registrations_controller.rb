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
            account_name: registration_params[:account_name],
          )

          if result.success?
            render(json: authentication_response(result.data), status: :created)
          else
            render_service_error(result, default_status: :unprocessable_entity)
          end
        end

        private

        def registration_params
          params.require(:data).require(:attributes).permit(:email, :password, :name, :account_name)
        end

        def authentication_response(data)
          AuthenticationSerializer.new(
            user: data.user,
            account: data.account,
            access_token: data.access_token,
            refresh_token: data.refresh_token,
            expires_in: data.expires_in,
          ).serializable_hash
        end
      end
    end
  end
end
