# frozen_string_literal: true

# JSON:API Configuration
#
# This initializer sets up the JSON:API content type for the application.
# Serialization is handled by the JsonapiRenderable concern and
# Api::V1::*Serializer classes using the jsonapi-serializer gem.
#
# The actual rendering logic is in:
# - app/controllers/concerns/jsonapi_renderable.rb (for render_jsonapi helper)
# - app/serializers/api/v1/* (for resource serializers)
#
# We intentionally DO NOT define a custom :jsonapi renderer here to avoid:
# 1. Polluting the global namespace with helper methods
# 2. Duplicating logic that exists in the JsonapiRenderable concern
# 3. Making debugging harder with implicit serializer inference
#
# Controllers should use the render_jsonapi method from JsonapiRenderable concern:
#   render_jsonapi @post, include: params[:include], meta: { total: 100 }
#
# Or render directly with explicit serializer:
#   render json: Api::V1::PostSerializer.new(@post).serializable_hash

# Register JSON:API MIME type
Mime::Type.register("application/vnd.api+json", :jsonapi)

# Configure Rails to parse JSON:API request bodies into params
# This tells Rails to treat application/vnd.api+json the same as application/json
# so that params[:data] and nested attributes are properly parsed
json_parser = ActionDispatch::Request.parameter_parsers[Mime[:json].symbol]
ActionDispatch::Request.parameter_parsers[Mime[:jsonapi].symbol] = json_parser
