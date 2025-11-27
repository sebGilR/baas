# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  before_validation :set_public_id, on: :create

  private

  def set_public_id
    self.public_id = SecureRandom.uuid if public_id.blank?
  end
end
