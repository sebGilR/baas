# frozen_string_literal: true

class ApplicationService
  class << self
    def call(*, **, &)
      new(*, **).call(&)
    end
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
