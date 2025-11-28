# frozen_string_literal: true

module Api
  module V1
    module Auth
      class BaseController < ::Api::V1::ApplicationController
        skip_before_action :authenticate_user!
      end
    end
  end
end
