# frozen_string_literal: true

module Api
  module V1
    # Base controller for all API v1 endpoints
    # Provides authentication, authorization, error handling,
    # pagination, filtering, and sorting capabilities
    class ApplicationController < ::ApplicationController
      include Pundit::Authorization
      include Authenticatable
      include ErrorHandling
      include Paginatable
      include Filterable
      include Sortable
      include JsonapiRenderable

      before_action :authenticate_user!

      # Override pundit_user to provide AuthorizationContext
      # This allows policies to access both user and account
      def pundit_user
        @pundit_user ||= AuthorizationContext.new(user: current_user, account: current_account)
      end

      # Helper to authorize collection with tenant scoping
      def authorize_collection(scope)
        policy_scope(scope.where(account: current_account))
      end
    end
  end
end
