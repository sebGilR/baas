# frozen_string_literal: true

module PublicIdentifiable
  extend ActiveSupport::Concern

  included do
    # Public ID is set by database default gen_uuidv7()
    # No need to set in Rails, but we validate presence
    validates :public_id, presence: true, uniqueness: true
  end

  class_methods do
    def find_by_public_id(public_id)
      find_by(public_id: public_id)
    end

    def find_by_public_id!(public_id)
      find_by!(public_id: public_id)
    end
  end

  def to_param
    public_id
  end
end
