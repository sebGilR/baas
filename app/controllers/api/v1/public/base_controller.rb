# frozen_string_literal: true

module Api
  module V1
    module Public
      class BaseController < ::Api::V1::ApplicationController
        skip_before_action :authenticate_user!
        before_action :clear_tenant_context

        private

        def clear_tenant_context
          ActsAsTenant.current_tenant = nil
        end
      end
    end
  end
end
