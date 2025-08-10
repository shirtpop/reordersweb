class Address < ApplicationRecord
  validates :street, :city, :state, :zip_code, presence: true

  before_update :prevent_changes

  private

  def prevent_changes
    raise ActiveRecord::ReadOnlyRecord, "Address records are immutable"
  end
end
