# frozen_string_literal: true

require "ostruct"

# Standardized result object for service responses
# Provides consistent success/failure handling with error codes
class ServiceResult
  attr_reader :data, :errors, :code

  # Standard error codes for consistent API responses
  # Maps to HTTP status codes in controllers
  module Codes
    # Authentication errors (401)
    INVALID_CREDENTIALS = "INVALID_CREDENTIALS"
    TOKEN_EXPIRED = "TOKEN_EXPIRED"
    TOKEN_INVALID = "TOKEN_INVALID"

    # Authorization errors (403)
    FORBIDDEN = "FORBIDDEN"

    # Resource errors (404)
    NOT_FOUND = "NOT_FOUND"

    # Validation errors (422)
    VALIDATION_FAILED = "VALIDATION_FAILED"

    # Conflict errors (409)
    ALREADY_EXISTS = "ALREADY_EXISTS"

    # Rate limiting (429)
    RATE_LIMIT_EXCEEDED = "RATE_LIMIT_EXCEEDED"
  end

  def initialize(success:, data: {}, errors: nil, code: nil)
    @success = success
    @data = data.is_a?(OpenStruct) ? data : OpenStruct.new(data)
    @errors = errors
    @code = code
  end

  def success?
    @success
  end

  def failure?
    !@success
  end
end
