# frozen_string_literal: true

module Api
  module V1
    # Controller for managing API keys
    # Allows users to create, list, and revoke their API keys
    #
    # Note: API key management must be done via JWT authentication,
    # not via API key authentication (to prevent privilege escalation)
    class ApiKeysController < ApplicationController
      before_action :authenticate_user!
      before_action :require_jwt_authentication!, except: [:index, :show]
      before_action :set_api_key, only: [:show, :update, :destroy, :revoke]

      # GET /api/v1/api_keys
      def index
        @api_keys = policy_scope(ApiKey, policy_scope_class: Core::ApiKeyPolicy::Scope)
          .order(created_at: :desc)

        # Optional status filter
        @api_keys = @api_keys.active if params[:status] == "active"
        @api_keys = @api_keys.revoked if params[:status] == "revoked"

        render_jsonapi(@api_keys, meta: { total: @api_keys.count })
      end

      # GET /api/v1/api_keys/:id
      def show
        render_jsonapi(@api_key)
      end

      # POST /api/v1/api_keys
      def create
        authorize(ApiKey, policy_class: Core::ApiKeyPolicy)

        result = Core::Authentication::CreateApiKeyService.call(
          user: current_user,
          account: current_account,
          name: api_key_params[:name],
          scopes: api_key_params[:scopes] || [],
          environment: api_key_params[:environment] || :live,
          expires_at: parse_expires_at
        )

        if result.success?
          # Return the raw token only once - this is the only time it's available
          render json: {
            data: {
              type: "api_key",
              id: result.api_key.public_id,
              attributes: {
                name: result.api_key.name,
                prefix: result.api_key.prefix,
                environment: result.api_key.environment,
                scopes: result.api_key.scopes,
                expires_at: result.api_key.expires_at,
                created_at: result.api_key.created_at,
                # IMPORTANT: This is the only time the full token is returned
                token: result.raw_token
              }
            },
            meta: {
              warning: "Store this token securely. It will not be shown again."
            }
          }, status: :created
        else
          render_error(:unprocessable_entity, detail: result.errors)
        end
      end

      # PATCH/PUT /api/v1/api_keys/:id
      # Only allows updating the name
      def update
        if @api_key.update(name: api_key_params[:name])
          render_jsonapi(@api_key)
        else
          render_error(:unprocessable_entity, detail: @api_key.errors.full_messages.join(", "))
        end
      end

      # DELETE /api/v1/api_keys/:id
      # Revokes the API key (soft delete)
      def destroy
        @api_key.revoke!
        head :no_content
      end

      # POST /api/v1/api_keys/:id/revoke
      # Explicit revoke action (alias for destroy)
      def revoke
        authorize @api_key, :revoke?, policy_class: Core::ApiKeyPolicy
        @api_key.revoke!
        render_jsonapi(@api_key)
      end

      private

      def set_api_key
        @api_key = ApiKey.find_by!(public_id: params[:id])
        authorize @api_key, policy_class: Core::ApiKeyPolicy
      end

      def api_key_params
        params.require(:data).require(:attributes).permit(:name, :environment, :expires_in_days, scopes: [])
      end

      def parse_expires_at
        expires_in_days = api_key_params[:expires_in_days]
        return nil if expires_in_days.blank?

        expires_in_days.to_i.days.from_now
      end

      # Prevent API key management via API key authentication
      # This prevents a compromised key from creating more keys
      def require_jwt_authentication!
        return unless authenticated_via_api_key?

        render json: {
          errors: [{
            status: "403",
            title: "Forbidden",
            detail: "API key management requires JWT authentication. Please use a Bearer token.",
            code: "JWT_REQUIRED"
          }]
        }, status: :forbidden
      end
    end
  end
end
