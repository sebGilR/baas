# frozen_string_literal: true

require "ostruct"

class ServiceResult
  attr_reader :data, :errors

  def initialize(success:, data: {}, errors: nil)
    @success = success
    @data = OpenStruct.new(data)
    @errors = errors
  end

  def success?
    @success
  end

  def failure?
    !@success
  end
end