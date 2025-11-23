# frozen_string_literal: true

# Base class for all service objects
# Provides a consistent interface for service execution
class ApplicationService
  # Service result object to encapsulate success/failure states
  Result = Struct.new(:success?, :errors, :data, keyword_init: true) do
    def failure?
      !success?
    end
  end

  # Class-level call method for convenient service invocation
  def self.call(*args, **kwargs, &block)
    new(*args, **kwargs).call(&block)
  end

  # Instance method to be implemented by subclasses
  def call
    raise NotImplementedError, "#{self.class} must implement #call"
  end

  private

  # Helper method to return success result
  def success(data = {})
    Result.new(success?: true, errors: nil, data: data)
  end

  # Helper method to return failure result
  def failure(errors:, data: {})
    Result.new(success?: false, errors: errors, data: data)
  end
end
