# frozen_string_literal: true

# Provides standardized error response helpers for API controllers
# Follows JSON:API-inspired error format
#
# @example Single error
#   render_error(:unauthorized,
#     title: "Authentication Failed",
#     detail: "Invalid email or password",
#     code: "INVALID_CREDENTIALS"
#   )
#
# @example Validation errors from ActiveModel
#   render_validation_errors(record.errors)
#
# @example From service result
#   render_service_error(result)
#
module ErrorHandling
  extend ActiveSupport::Concern

  # Maps ServiceResult error codes to HTTP status codes
  CODE_TO_STATUS = {
    ServiceResult::Codes::INVALID_CREDENTIALS => :unauthorized,
    ServiceResult::Codes::TOKEN_EXPIRED => :unauthorized,
    ServiceResult::Codes::TOKEN_INVALID => :unauthorized,
    ServiceResult::Codes::FORBIDDEN => :forbidden,
    ServiceResult::Codes::NOT_FOUND => :not_found,
    ServiceResult::Codes::VALIDATION_FAILED => :unprocessable_entity,
    ServiceResult::Codes::ALREADY_EXISTS => :conflict,
    ServiceResult::Codes::RATE_LIMIT_EXCEEDED => :too_many_requests,
  }.freeze

  # Maps HTTP status codes to default titles
  STATUS_TITLES = {
    bad_request: "Bad Request",
    unauthorized: "Unauthorized",
    forbidden: "Forbidden",
    not_found: "Not Found",
    conflict: "Conflict",
    unprocessable_entity: "Unprocessable Entity",
    too_many_requests: "Too Many Requests",
    internal_server_error: "Internal Server Error",
  }.freeze

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
    rescue_from ActionController::ParameterMissing, with: :handle_bad_request
  end

  private

  # Render a single error response
  # @param status [Symbol, Integer] HTTP status code
  # @param title [String] Short error title
  # @param detail [String] Detailed error message
  # @param code [String, nil] Machine-readable error code
  # @param source [Hash, nil] Pointer to error source
  def render_error(status, title:, detail:, code: nil, source: nil)
    status_code = Rack::Utils.status_code(status)

    error_object = {
      status: status_code.to_s,
      code: code,
      title: title,
      detail: detail,
      source: source,
    }.compact

    render(json: { errors: [error_object] }, status: status)
  end

  # Render validation errors from ActiveModel::Errors
  # @param errors [ActiveModel::Errors] Rails validation errors
  # @param status [Symbol] HTTP status code (default: :unprocessable_entity)
  def render_validation_errors(errors, status: :unprocessable_entity)
    status_code = Rack::Utils.status_code(status)

    error_objects = errors.map do |error|
      {
        status: status_code.to_s,
        code: ServiceResult::Codes::VALIDATION_FAILED,
        title: "Validation Error",
        detail: error.full_message,
        source: { pointer: "/data/attributes/#{error.attribute}" },
      }
    end

    render(json: { errors: error_objects }, status: status)
  end

  # Render error from a ServiceResult failure
  # Maps result.code to appropriate HTTP status
  # @param result [ServiceResult] Failed service result
  # @param default_status [Symbol] Fallback status if code not mapped
  def render_service_error(result, default_status: :unprocessable_entity)
    status = CODE_TO_STATUS[result.code] || default_status
    title = STATUS_TITLES[status] || "Error"

    render_error(
      status,
      title: title,
      detail: format_errors(result.errors),
      code: result.code,
    )
  end

  # Handle ActiveRecord::RecordNotFound exceptions
  def handle_not_found(exception)
    render_error(
      :not_found,
      title: "Not Found",
      detail: exception.message,
      code: ServiceResult::Codes::NOT_FOUND,
    )
  end

  # Handle ActiveRecord::RecordInvalid exceptions
  def handle_record_invalid(exception)
    render_validation_errors(exception.record.errors)
  end

  # Handle ActionController::ParameterMissing exceptions
  def handle_bad_request(exception)
    render_error(
      :bad_request,
      title: "Bad Request",
      detail: exception.message,
      code: "BAD_REQUEST",
    )
  end

  # Format errors for display
  # @param errors [String, Array, Hash, ActiveModel::Errors] Error data
  # @return [String]
  def format_errors(errors)
    case errors
    when String
      errors
    when Array
      errors.join(", ")
    when Hash
      errors.values.flatten.join(", ")
    when ActiveModel::Errors
      errors.full_messages.join(", ")
    else
      errors.to_s
    end
  end
end
