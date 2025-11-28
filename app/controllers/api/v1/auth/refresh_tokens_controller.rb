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
            render(json: token_response(result), status: :ok)
          else
            render(json: error_response("401", "Token Refresh Failed", result.errors), status: :unauthorized)
          end
        end

        def destroy
          result = Core::Authentication::LogoutService.call(
            refresh_token: refresh_params[:refresh_token],
          )

          if result.success?
            head(:no_content)
          else
            render(json: error_response("400", "Logout Failed", result.errors), status: :bad_request)
          end
        end

        private

        def refresh_params
          params.require(:data).require(:attributes).permit(:refresh_token)
        end

        def token_response(result)
          {
            data: {
              type: "authentication",
              attributes: {
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
