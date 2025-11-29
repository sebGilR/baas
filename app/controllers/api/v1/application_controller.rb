# frozen_string_literal: true

module Api
  module V1
    # Base controller for all API v1 endpoints
    # Provides authentication, authorization, error handling,
    # pagination, filtering, and sorting capabilities
    class ApplicationController < ::ApplicationController
      include Pundit::Authorization
      include ErrorHandling
      include Paginatable
      include Filterable
      include Sortable

      before_action :authenticate_user!

      private

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

        render_error(
          :unauthorized,
          title: "Unauthorized",
          detail: "You must be authenticated to access this resource.",
          code: ServiceResult::Codes::TOKEN_INVALID,
        )
      end

      # Helper to authorize collection with tenant scoping
      def authorize_collection(scope)
        policy_scope(scope.where(account: current_account))
      end
    end
  end
end
