# frozen_string_literal: true

# Base class for all service objects
# Provides a consistent interface for calling services and returning results
#
# @example
#   class MyService < ApplicationService
#     def initialize(param:)
#       @param = param
#     end
#
#     def call
#       return failure(errors: "Invalid", code: Codes::VALIDATION_FAILED) unless valid?
#       success(data: @param)
#     end
#   end
#
#   result = MyService.call(param: "value")
#   result.success? # => true
#   result.data     # => OpenStruct with data
#
class ApplicationService
  # Convenience alias for error codes
  Codes = ServiceResult::Codes

  class << self
    def call(*, **, &)
      new(*, **).call(&)
    end
  end

  def call
    raise NotImplementedError
  end

  private

  # Returns a successful result with optional data
  # @param data [Hash] Data to include in the result
  # @return [ServiceResult]
  def success(data = {})
    ServiceResult.new(success: true, data: data)
  end

  # Returns a failure result with errors and optional error code
  # @param errors [String, Array] Error message(s)
  # @param code [String, nil] Error code from ServiceResult::Codes
  # @param data [Hash] Optional data to include even on failure
  # @return [ServiceResult]
  def failure(errors:, code: nil, data: {})
    ServiceResult.new(success: false, errors: errors, code: code, data: data)
  end
end
