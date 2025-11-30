# frozen_string_literal: true

require "rails_helper"

# Dummy model for filtering
class FilterablePost < ApplicationRecord
  self.table_name = "users" # Use users table for simplicity
end

# Dummy controller to test the concern
class FilterableTestController < ApplicationController
  include Filterable

  def index
    scope = FilterablePost.all
    filtered_scope = apply_filters(scope)
    render(json: { count: filtered_scope.count })
  end

  private

  def allowed_filters
    [:name, :email]
  end
end

RSpec.describe(Filterable, type: :controller) do
  controller(FilterableTestController) do
    class << self
      def controller_path
        "filterable_test"
      end
    end
  end

  before do
    routes.draw do
      get "index" => "filterable_test#index"
    end
    # Create some data to filter
    create(:user, name: "Alice", email: "alice@example.com")
    create(:user, name: "Bob", email: "bob@example.com")
    create(:user, name: "Charlie", email: "charlie@example.com")
  end

  describe "#apply_filters" do
    it "does not filter if no filter params are provided" do
      get :index
      expect(response).to(have_http_status(:ok))
      json = response.parsed_body
      expect(json["count"]).to(eq(3))
    end

    it "filters by a single allowed attribute" do
      get :index, params: { filter: { name: "Alice" } }
      json = response.parsed_body
      expect(json["count"]).to(eq(1))
    end

    it "filters by multiple allowed attributes" do
      get :index, params: { filter: { name: "Bob", email: "bob@example.com" } }
      json = response.parsed_body
      expect(json["count"]).to(eq(1))
    end

    it "handles comma-separated values for an attribute" do
      get :index, params: { filter: { name: "Alice,Charlie" } }
      json = response.parsed_body
      expect(json["count"]).to(eq(2))
    end

    it "ignores filters that are not in allowed_filters" do
      # 'id' is not in allowed_filters
      get :index, params: { filter: { name: "Alice", id: User.first.id } }
      json = response.parsed_body
      expect(json["count"]).to(eq(1)) # Only filters by name
    end

    it "returns an empty result if no records match" do
      get :index, params: { filter: { name: "Unknown" } }
      json = response.parsed_body
      expect(json["count"]).to(eq(0))
    end
  end
end
