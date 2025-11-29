# frozen_string_literal: true

module Api
  module V1
    module Auth
      class RefreshTokensController < BaseController
        def create
          result = Core::Authentication::RefreshTokenService.call(
            refresh_token: refresh_params[:refresh_token],
          )

          if result.success?
            render(json: token_response(result.data), status: :ok)
          else
            render_service_error(result, default_status: :unauthorized)
          end
        end

        def destroy
          result = Core::Authentication::LogoutService.call(
            refresh_token: refresh_params[:refresh_token],
          )

          if result.success?
            head(:no_content)
          else
            render_service_error(result, default_status: :bad_request)
          end
        end

        private

        def refresh_params
          params.require(:data).require(:attributes).permit(:refresh_token)
        end

        def token_response(data)
          TokenSerializer.new(
            access_token: data.access_token,
            refresh_token: data.refresh_token,
            expires_in: data.expires_in,
          ).serializable_hash
        end
      end
    end
  end
end
