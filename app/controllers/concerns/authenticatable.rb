# frozen_string_literal: true

# Concern for multi-strategy authentication
# Supports both JWT tokens and API keys
# Sets current_user, current_account, and optionally current_api_key for the request
#
# Authentication strategies (tried in order):
# 1. JWT Bearer token: "Authorization: Bearer <jwt>"
# 2. API Key: "Authorization: ApiKey <prefix.secret>"
#
module Authenticatable
  extend ActiveSupport::Concern

  included do
    attr_reader :current_user, :current_account, :current_api_key
  end

  private

  # Authenticate user via JWT token or API key from Authorization header
  # Tries JWT first, then falls back to API key
  def authenticate_user!
    auth_header = request.headers["Authorization"]
    return render_unauthorized("Missing authorization token") if auth_header.blank?

    # Try JWT authentication first
    if auth_header.start_with?("Bearer ")
      authenticate_with_jwt!(auth_header)
    # Then try API key authentication
    elsif auth_header.start_with?("ApiKey ")
      authenticate_with_api_key!(auth_header)
    else
      render_unauthorized("Invalid authorization header format")
    end
  end

  # Authenticate using JWT Bearer token
  def authenticate_with_jwt!(auth_header)
    token = auth_header.split(" ").last
    result = Core::Authentication::DecodeJwtService.call(token: token)
    return render_unauthorized(result.errors) unless result.success?

    payload = result.payload
    @current_user = find_user_from_payload(payload)
    return render_unauthorized("User not found") unless @current_user

    @current_account = find_account_from_payload(payload)
    return render_unauthorized("Account not found") unless @current_account

    # Set tenant context for acts_as_tenant
    set_tenant_context
  end

  # Authenticate using API key
  def authenticate_with_api_key!(auth_header)
    raw_token = auth_header.split(" ", 2).last
    result = Core::Authentication::AuthenticateWithApiKeyService.call(
      raw_token: raw_token,
      ip_address: request.remote_ip
    )

    return render_unauthorized(result.errors) unless result.success?

    @current_user = result.user
    @current_account = result.account
    @current_api_key = result.api_key

    # Set tenant context for acts_as_tenant
    set_tenant_context
  end

  # Check if current request is authenticated via API key
  def authenticated_via_api_key?
    current_api_key.present?
  end

  # Require specific scopes for API key authentication
  # Does nothing for JWT authentication (full access)
  def require_api_key_scopes!(*required_scopes)
    return unless authenticated_via_api_key?
    return if current_api_key.has_scopes?(required_scopes)

    render_forbidden("API key missing required scopes: #{required_scopes.join(', ')}")
  end

  # Extract Bearer token from Authorization header (kept for backwards compatibility)
  def extract_token_from_header
    auth_header = request.headers["Authorization"]
    return unless auth_header&.start_with?("Bearer ")

    auth_header.split(" ").last
  end

  # Find user from JWT payload using public_id (sub claim)
  def find_user_from_payload(payload)
    user_public_id = payload["sub"]
    return unless user_public_id

    User.find_by(public_id: user_public_id)
  end

  # Find account from JWT payload using account_id claim
  def find_account_from_payload(payload)
    account_public_id = payload["account_id"]
    return unless account_public_id

    # Verify user has access to this account
    account = Account.find_by(public_id: account_public_id)
    return unless account
    return if @current_user.accounts.exclude?(account)

    account
  end

  # Set tenant context for row-level tenancy
  def set_tenant_context
    ActsAsTenant.current_tenant = @current_account
  end

  # Render unauthorized response
  def render_unauthorized(detail)
    render(
      json: {
        errors: [{
          status: "401",
          title: "Unauthorized",
          detail: detail,
          code: "TOKEN_INVALID",
        }],
      },
      status: :unauthorized,
    )
  end

  # Render forbidden response (for scope issues)
  def render_forbidden(detail)
    render(
      json: {
        errors: [{
          status: "403",
          title: "Forbidden",
          detail: detail,
          code: "INSUFFICIENT_SCOPE",
        }],
      },
      status: :forbidden,
    )
  end
end
