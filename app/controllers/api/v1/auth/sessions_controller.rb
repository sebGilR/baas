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
            render(json: authentication_response(result.data), status: :ok)
          else
            render_service_error(result, default_status: :unauthorized)
          end
        end

        private

        def login_params
          params.require(:data).require(:attributes).permit(:email, :password)
        end

        def extract_device_info
          { user_agent: request.user_agent, ip_address: request.remote_ip }
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
