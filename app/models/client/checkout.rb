class Client::Checkout < ApplicationRecord
  belongs_to :client
  belongs_to :user

  has_many :inventory_movements, class_name: "Client::InventoryMovement", dependent: :nullify, foreign_key: :client_checkout_id
  has_many :checkout_items, class_name: "Client::CheckoutItem", foreign_key: :client_checkout_id, dependent: :destroy

  enum :status, { draft: "draft", confirmed: "confirmed" }, default: :confirmed

  validates :purpose, :recipient_first_name, :recipient_last_name, presence: true, if: :confirmed?

  scope :search_by_name, ->(name) {
    where("#{table_name}.recipient_first_name ILIKE :name OR
          #{table_name}.recipient_last_name ILIKE :name",
          name: "%#{sanitize_sql_like(name)}%")
  }

  scope :created_from, ->(date) { where("#{table_name}.created_at >= ?", date.to_date.beginning_of_day) }
  scope :created_to, ->(date) { where("#{table_name}.created_at <= ?", date.to_date.end_of_day) }

  def recipient_full_name
    "#{recipient_first_name.humanize} #{recipient_last_name.humanize}"
  end
end
