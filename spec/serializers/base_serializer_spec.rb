# frozen_string_literal: true

require "rails_helper"

RSpec.describe(BaseSerializer) do
  # Test subclass for testing base behavior
  let(:test_serializer_class) do
    Class.new(described_class) do
      def initialize(data:)
        @data = data
      end

      def serializable_hash
        {
          data: {
            type: "test",
            attributes: @data,
          },
        }
      end
    end
  end

  describe ".render" do
    it "creates an instance and calls serializable_hash" do
      result = test_serializer_class.render(data: { name: "test" })

      expect(result).to(eq({
        data: {
          type: "test",
          attributes: { name: "test" },
        },
      }))
    end
  end

  describe "#serializable_hash" do
    context "when not implemented in subclass" do
      let(:base_instance) { described_class.new }

      it "raises NotImplementedError" do
        expect { base_instance.serializable_hash }.to(raise_error(
          NotImplementedError,
          "BaseSerializer must implement #serializable_hash",
        ))
      end
    end
  end

  describe "#as_json" do
    it "returns the same as serializable_hash" do
      serializer = test_serializer_class.new(data: { foo: "bar" })

      expect(serializer.as_json).to(eq(serializer.serializable_hash))
    end
  end

  describe "#format_timestamp" do
    let(:serializer_with_timestamp) do
      Class.new(described_class) do
        def initialize(time:)
          @time = time
        end

        def serializable_hash
          { timestamp: format_timestamp(@time) }
        end
      end
    end

    it "formats Time objects to ISO8601" do
      time = Time.zone.parse("2025-12-06T12:00:00Z")
      serializer = serializer_with_timestamp.new(time: time)

      expect(serializer.serializable_hash[:timestamp]).to(eq(time.iso8601))
    end

    it "returns nil for nil values" do
      serializer = serializer_with_timestamp.new(time: nil)

      expect(serializer.serializable_hash[:timestamp]).to(be_nil)
    end
  end

  describe "#extract_attributes" do
    let(:record) do
      Struct.new(:name, :email, :created_at).new(
        "John",
        "john@example.com",
        Time.zone.parse("2025-12-06T12:00:00Z"),
      )
    end

    let(:serializer_with_attributes) do
      Class.new(described_class) do
        def initialize(record:)
          @record = record
        end

        def serializable_hash
          { attributes: extract_attributes(@record, :name, :email, :created_at) }
        end
      end
    end

    it "extracts specified attributes from record" do
      serializer = serializer_with_attributes.new(record: record)
      result = serializer.serializable_hash[:attributes]

      expect(result[:name]).to(eq("John"))
      expect(result[:email]).to(eq("john@example.com"))
    end

    it "formats Time attributes to ISO8601" do
      serializer = serializer_with_attributes.new(record: record)
      result = serializer.serializable_hash[:attributes]

      expect(result[:created_at]).to(eq(record.created_at.iso8601))
    end
  end
end
