# frozen_string_literal: true

class SolidQueue::RecurringJob < ActiveJob::Base
  def perform(command)
    SolidQueue.instrument(:run_command, command: command) do
      eval(command, TOPLEVEL_BINDING, __FILE__, __LINE__)
    end
  end
end
