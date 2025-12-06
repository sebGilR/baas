# frozen_string_literal: true

# Concern for JWT-based authentication
# Extracts and validates JWT tokens from Authorization header
# Sets current_user and current_account for the request
module Authenticatable
  extend ActiveSupport::Concern

  included do
    attr_reader :current_user, :current_account
  end

  private

  # Authenticate user via JWT token from Authorization header
  def authenticate_user!
    token = extract_token_from_header
    return render_unauthorized("Missing authorization token") unless token

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

  # Extract Bearer token from Authorization header
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
end
