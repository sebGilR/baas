# frozen_string_literal: true

# Concern for rendering JSON:API compliant responses
#
# Uses jsonapi-serializer gem to serialize resources. This is the single
# entry point for JSON:API rendering in controllers.
#
# @example Basic usage
#   render_jsonapi @post
#
# @example With includes and meta
#   render_jsonapi @posts,
#     include: params[:include],
#     meta: pagination_meta(@posts)
#
# @example With explicit serializer
#   render_jsonapi @user, serializer: Api::V1::AdminUserSerializer
#
module JsonapiRenderable
  extend ActiveSupport::Concern

  private

  # Render a resource in JSON:API format
  # @param resource [Object, Array] The resource(s) to serialize
  # @param options [Hash] Options for rendering
  # @option options [Symbol] :status HTTP status code (default: :ok)
  # @option options [Class] :serializer Serializer class to use (auto-inferred if not provided)
  # @option options [Array<String>, String] :include Relationships to include
  # @option options [Hash] :meta Metadata to include in response
  # @option options [Hash] :links Links to include in response
  # @option options [Hash] :params Additional params to pass to serializer
  def render_jsonapi(resource, options = {})
    status = options.delete(:status) || :ok
    serializer = options.delete(:serializer) || infer_serializer(resource)

    serializer_options = build_serializer_options(options)
    json = serializer.new(resource, serializer_options).serializable_hash

    render(json: json, status: status)
  end

  # Infer the serializer class from the resource
  # Handles ActiveRecord collections, arrays, and single records
  # Strips module namespaces (e.g., Publishing::Post -> PostSerializer)
  #
  # @param resource [Object] The resource to infer serializer for
  # @return [Class] The serializer class
  # @raise [NameError] If no serializer is found
  def infer_serializer(resource)
    klass = extract_resource_class(resource)
    serializer_name = "Api::V1::#{klass.name.demodulize}Serializer"
    serializer_name.constantize
  rescue NameError => e
    Rails.logger.error(
      "[JsonapiRenderable] Could not find serializer: #{serializer_name} for #{klass.name} - #{e.message}",
    )
    raise
  end

  # Extract the class from various resource types
  # @param resource [Object] ActiveRecord relation, array, or single record
  # @return [Class] The model class
  def extract_resource_class(resource)
    if resource.respond_to?(:klass)
      # ActiveRecord::Relation
      resource.klass
    elsif resource.respond_to?(:model)
      # Pagy or similar paginated result
      resource.model
    elsif resource.is_a?(Array) && resource.first
      # Plain array
      resource.first.class
    else
      # Single record
      resource.class
    end
  end

  # Build options hash for jsonapi-serializer
  # @param options [Hash] Raw options from render_jsonapi call
  # @return [Hash] Cleaned options for serializer
  def build_serializer_options(options)
    {
      include: parse_include(options.delete(:include)),
      meta: options.delete(:meta),
      links: options.delete(:links),
      fields: parse_fields(options.delete(:fields)),
      params: options.delete(:params) || {},
    }.compact
  end

  # Parse include parameter into array format
  # @param include_param [String, Array, nil] Include parameter from request
  # @return [Array, nil] Parsed includes
  def parse_include(include_param)
    return if include_param.blank?
    return include_param if include_param.is_a?(Array)

    include_param.to_s.split(",").map(&:strip)
  end

  # Parse sparse fieldsets parameter
  # @param fields_param [Hash, nil] Fields parameter from request
  # @return [Hash, nil] Parsed fields
  def parse_fields(fields_param)
    return if fields_param.blank?

    fields_param.transform_values do |value|
      value.is_a?(String) ? value.split(",").map(&:strip).map(&:to_sym) : value
    end
  end
end
