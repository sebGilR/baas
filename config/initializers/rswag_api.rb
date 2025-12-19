# frozen_string_literal: true

Rswag::Api.configure do |c|
  # Specify a root folder where Swagger JSON files are located
  # This is used by the Swagger middleware to serve requests for API descriptions
  c.openapi_root = Rails.root.join("swagger").to_s
end