# frozen_string_literal: true

module Api
  module V1
    module Auth
      class SessionsController < BaseController
        def create
          result = Core::Authentication::LoginService.call(
            email: login_params[:email],
            password: login_params[:password],
            device_info: extract_device_info,
          )

          if result.success?
            render(json: authentication_response(result), status: :ok)
          else
            render(json: error_response("401", "Authentication Failed", result.errors), status: :unauthorized)
          end
        end

        private

        def login_params
          params.require(:data).require(:attributes).permit(:email, :password)
        end

        def extract_device_info
          { user_agent: request.user_agent, ip_address: request.remote_ip }
        end

        def authentication_response(result)
          {
            data: {
              type: "authentication",
              attributes: build_auth_attributes(result),
            },
          }
        end

        def build_auth_attributes(result)
          {
            user: UserSerializer.new(result.data.user).serializable_hash[:data][:attributes],
            account: AccountSerializer.new(result.data.account).serializable_hash[:data][:attributes],
            access_token: result.data.access_token,
            refresh_token: result.data.refresh_token,
            token_type: "Bearer",
            expires_in: result.data.expires_in,
          }
        end

        def error_response(status, title, detail)
          { errors: [{ status: status, title: title, detail: detail }] }
        end
      end
    end
  end
end
