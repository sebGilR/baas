# frozen_string_literal: true

class ApplicationService
  def self.call(*args, **kwargs, &block)
    new(*args, **kwargs).call(&block)
  end

  def call
    raise NotImplementedError
  end

  private

  def success(data = {})
    ServiceResult.new(success: true, data: data)
  end

  def failure(errors:, data: {})
    ServiceResult.new(success: false, errors: errors, data: data)
  end
end