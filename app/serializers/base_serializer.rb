# frozen_string_literal: true

# Base class for PORO (Plain Old Ruby Object) serializers
#
# Use this base class for non-ActiveRecord serializers that need to
# render custom JSON:API-like responses (e.g., authentication responses,
# aggregated data, or composite objects).
#
# For ActiveRecord models, use jsonapi-serializer gem directly by
# including JSONAPI::Serializer in your serializer class.
#
# @example Basic usage
#   class Api::V1::AuthenticationSerializer < BaseSerializer
#     def initialize(user:, token:)
#       @user = user
#       @token = token
#     end
#
#     def serializable_hash
#       {
#         data: {
#           type: "authentication",
#           attributes: {
#             user: serialize_user,
#             token: @token
#           }
#         }
#       }
#     end
#   end
#
# @example Rendering in controller
#   render json: Api::V1::AuthenticationSerializer.new(
#     user: @user,
#     token: token
#   ).serializable_hash
#
class BaseSerializer
  class << self
    # Class method for convenient one-liner rendering
    # @param args [Hash] Arguments to pass to the initializer
    # @return [Hash] The serialized hash
    def render(**args)
      new(**args).serializable_hash
    end
  end

  # Return the serializable hash representation
  # Must be implemented by subclasses
  # @return [Hash] JSON:API-compliant hash
  def serializable_hash
    raise NotImplementedError, "#{self.class} must implement #serializable_hash"
  end

  # Alias for compatibility with to_json
  # @return [Hash]
  def as_json(*)
    serializable_hash
  end

  protected

  # Format a timestamp in ISO8601 format
  # @param time [Time, DateTime, nil] The timestamp to format
  # @return [String, nil] ISO8601 formatted timestamp
  def format_timestamp(time)
    time&.iso8601
  end

  # Format an attribute hash for JSON:API
  # @param record [Object] The record to serialize
  # @param attributes [Array<Symbol>] The attributes to include
  # @return [Hash] The attributes hash
  def extract_attributes(record, *attributes)
    attributes.flatten.each_with_object({}) do |attr, hash|
      value = record.public_send(attr)
      hash[attr] = value.is_a?(Time) ? format_timestamp(value) : value
    end
  end
end
