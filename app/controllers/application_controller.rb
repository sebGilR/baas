# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Pundit::Authorization
  include Authenticatable

  before_action :authenticate_user!

  # Pundit authorization callbacks
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def pundit_user
    AuthorizationContext.new(user: current_user, account: current_account)
  end

  def user_not_authorized
    render(
      json: {
        errors: [{
          status: "403",
          title: "Forbidden",
          detail: "You are not authorized to perform this action.",
        }],
      },
      status: :forbidden,
    )
  end
end
