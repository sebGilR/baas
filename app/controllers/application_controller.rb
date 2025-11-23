# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Pundit::Authorization

  # Pundit authorization callbacks
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    render json: {
      errors: [{
        status: "403",
        title: "Forbidden",
        detail: "You are not authorized to perform this action."
      }]
    }, status: :forbidden
  end
end
