# This is a third test comment to trigger the code review workflow.
module Api
  module V1
    class HealthController < ApplicationController
      skip_before_action :authenticate_user!, only: [:show]

      def show
        render json: {
          status: 'ok',
          timestamp: Time.current.iso8601,
          environment: Rails.env,
          version: '1.0.0',
          services: {
            database: database_status,
            redis: redis_status
          }
        }
      end

      private

      def database_status
        ActiveRecord::Base.connection.execute('SELECT 1')
        'connected'
      rescue StandardError => e
        { error: e.message }
      end

      def redis_status
        # Redis check will be implemented when we configure Redis
        'not configured'
      rescue StandardError => e
        { error: e.message }
      end
    end
  end
end
