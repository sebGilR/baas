# frozen_string_literal: true

# Helper module for rswag request specs
module RswagHelpers
  extend ActiveSupport::Concern

  included do
    # Common let definitions for API specs
    let(:Authorization) { authorization_header }
  end

  # JSON:API request body helper
  def jsonapi_body(type:, attributes:, relationships: nil)
    body = {
      data: {
        type: type,
        attributes: attributes,
      },
    }

    body[:data][:relationships] = relationships if relationships
    body
  end

  # JSON:API relationship helper
  def jsonapi_relationship(type:, id:)
    {
      data: {
        type: type,
        id: id,
      },
    }
  end
end

RSpec.configure do |config|
  config.include RswagHelpers, type: :request
end
