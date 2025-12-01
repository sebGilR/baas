# frozen_string_literal: true

RSpec.configure do |config|
  config.include(Pundit::Matchers, type: :policy)
end
