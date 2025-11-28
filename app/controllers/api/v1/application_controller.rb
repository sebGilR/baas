# frozen_string_literal: true

module Api
  module V1
    class ApplicationController < ::ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_content
      before_action :authenticate_user!

      private

      def not_found(exception)
        render(
          json: {
            errors: [{
              status: "404",
              title: "Not Found",
              detail: exception.message,
            }],
          },
          status: :not_found,
        )
      end

      def unprocessable_content(exception)
        render(
          json: {
            errors: [{
              status: "422",
              title: "Unprocessable Entity",
              detail: exception.message,
            }],
          },
          status: :unprocessable_content,
        )
      end

      # Returns the current authenticated user
      # To be implemented once JWT authentication is set up
      def current_user
        @current_user ||= nil # Will be set by JWT authentication
      end

      # Returns the current tenant account
      # To be implemented once multi-tenancy is set up
      def current_account
        @current_account ||= nil # Will be set by tenant context
      end

      # Authenticate user via JWT token
      # To be implemented
      def authenticate_user!
        # TODO: Implement JWT authentication
        # For now, return unauthorized
        return if current_user

        render(
          json: {
            errors: [{
              status: "401",
              title: "Unauthorized",
              detail: "You must be authenticated to access this resource.",
            }],
          },
          status: :unauthorized,
        )
      end

      # Helper to authorize collection with tenant scoping
      def authorize_collection(scope)
        policy_scope(scope.where(account: current_account))
      end
    end
  end
end
