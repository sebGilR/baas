# frozen_string_literal: true

require "rails_helper"

# Dummy controller to test the concern
class ErrorsTestController < ApplicationController
  include ErrorHandling

  def single_error
    render_error(
      :unauthorized,
      title: "Auth Error",
      detail: "Invalid token",
      code: "TOKEN_INVALID",
      source: { pointer: "/data/attributes/token" },
    )
  end

  def validation_errors
    user = User.new
    user.valid? # trigger validation
    render_validation_errors(user.errors)
  end

  def service_error
    result = ServiceResult.new(success: false, errors: "Something went wrong", code: ServiceResult::Codes::INVALID_CREDENTIALS)
    render_service_error(result, default_status: :bad_request)
  end

  def not_found
    raise ActiveRecord::RecordNotFound, "Couldn't find User with 'id'=123"
  end

  def record_invalid
    user = User.new
    user.valid? # Trigger validations to populate errors
    raise ActiveRecord::RecordInvalid, user
  end

  def parameter_missing
    raise ActionController::ParameterMissing, :name
  end
end

RSpec.describe(ErrorHandling, type: :controller) do
  controller(ErrorsTestController) do
    # Define routes for the dummy controller actions
    class << self
      def controller_path
        "errors_test"
      end
    end
  end

  before do
    routes.draw do
      get "single_error" => "errors_test#single_error"
      get "validation_errors" => "errors_test#validation_errors"
      get "service_error" => "errors_test#service_error"
      get "not_found" => "errors_test#not_found"
      get "record_invalid" => "errors_test#record_invalid"
      get "parameter_missing" => "errors_test#parameter_missing"
    end
  end

  describe "#render_error" do
    # rubocop:disable RSpec/MultipleExpectations
    it "renders a single JSON:API error" do
      get :single_error
      expect(response).to(have_http_status(:unauthorized))
      json = response.parsed_body
      expect(json["errors"]).to(be_an(Array))
      expect(json["errors"].size).to(eq(1))
      error = json["errors"].first
      expect(error["status"]).to(eq("401"))
      expect(error["title"]).to(eq("Auth Error"))
      expect(error["detail"]).to(eq("Invalid token"))
      expect(error["code"]).to(eq("TOKEN_INVALID"))
      expect(error["source"]).to(eq({ "pointer" => "/data/attributes/token" }))
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe "#render_validation_errors" do
    it "renders multiple JSON:API errors from ActiveModel::Errors" do
      get :validation_errors
      expect(response).to(have_http_status(:unprocessable_content))
      json = response.parsed_body
      expect(json["errors"]).to(be_an(Array))
      expect(json["errors"].size).to(be > 1)

      email_error = json["errors"].find { |e| e.dig("source", "pointer") == "/data/attributes/email" }
      expect(email_error["detail"]).to(eq("Email can't be blank"))
      expect(email_error["title"]).to(eq("Validation Error"))
      expect(email_error["code"]).to(eq("VALIDATION_FAILED"))
    end
  end

  describe "#render_service_error" do
    it "renders an error from a ServiceResult" do
      get :service_error
      expect(response).to(have_http_status(:unauthorized)) # Mapped from INVALID_CREDENTIALS
      json = response.parsed_body
      error = json["errors"].first
      expect(error["status"]).to(eq("401"))
      expect(error["title"]).to(eq("Unauthorized"))
      expect(error["detail"]).to(eq("Something went wrong"))
      expect(error["code"]).to(eq("INVALID_CREDENTIALS"))
    end
  end

  describe "exception handling" do
    it "handles ActiveRecord::RecordNotFound" do
      get :not_found
      expect(response).to(have_http_status(:not_found))
      json = response.parsed_body
      error = json["errors"].first
      expect(error["title"]).to(eq("Not Found"))
      expect(error["detail"]).to(eq("Couldn't find User with 'id'=123"))
      expect(error["code"]).to(eq("NOT_FOUND"))
    end

    it "handles ActiveRecord::RecordInvalid" do
      get :record_invalid
      expect(response).to(have_http_status(:unprocessable_content))
      json = response.parsed_body
      expect(json["errors"]).to(be_an(Array))
      expect(json["errors"]).not_to(be_empty)
      expect(json["errors"].first["title"]).to(eq("Validation Error"))
    end

    it "handles ActionController::ParameterMissing" do
      get :parameter_missing
      expect(response).to(have_http_status(:bad_request))
      json = response.parsed_body
      error = json["errors"].first
      expect(error["title"]).to(eq("Bad Request"))
      expect(error["detail"]).to(eq("param is missing or the value is empty or invalid: name"))
      expect(error["code"]).to(eq("BAD_REQUEST"))
    end
  end
end
