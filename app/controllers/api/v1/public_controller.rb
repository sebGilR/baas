# frozen_string_literal: true

module Api
  module V1
    class PublicController < ApplicationController
      skip_before_action :authenticate_user!

      def show
        render(json: { message: "hello" })
      end
    end
  end
end
