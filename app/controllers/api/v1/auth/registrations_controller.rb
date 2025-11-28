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
            render(json: success_response(result), status: :created)
          else
            render(json: error_response("422", "Registration Failed", result.errors), status: :unprocessable_content)
          end
        end

        private

        def registration_params
          params.require(:data).require(:attributes).permit(:email, :password, :name, :account_name)
        end

        def success_response(result)
          {
            data: {
              type: "authentication",
              attributes: {
                user: UserSerializer.new(result.data.user).serializable_hash[:data][:attributes],
                account: AccountSerializer.new(result.data.account).serializable_hash[:data][:attributes],
                access_token: result.data.access_token,
                refresh_token: result.data.refresh_token,
                token_type: "Bearer",
                expires_in: result.data.expires_in,
              },
            },
          }
        end

        def error_response(status, title, detail)
          { errors: [{ status: status, title: title, detail: detail }] }
        end
      end
    end
  end
end
