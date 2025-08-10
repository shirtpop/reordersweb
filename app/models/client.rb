class Client < ApplicationRecord
  belongs_to :address, optional: true
  belongs_to :shipping_address, class_name: 'Address', optional: true

  has_many :users, inverse_of: :client, dependent: :destroy

  validates :company_name, :personal_name, :phone_number, presence: true

  scope :search_by_name, ->(query) {
    sanitized_query = "%#{sanitize_sql_like(query)}%"
    where("#{table_name}.company_name ILIKE ?", sanitized_query)
    .or(where("#{table_name}.personal_name ILIKE ?", sanitized_query))
  }

  accepts_nested_attributes_for :address
  accepts_nested_attributes_for :shipping_address
  accepts_nested_attributes_for :users, allow_destroy: true
end
