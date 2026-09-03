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

  scope :sorted_by, ->(sort_by) {
    case sort_by
    when "recipient_asc"
      order(:recipient_first_name, :recipient_last_name)
    when "recipient_desc"
      order(recipient_first_name: :desc, recipient_last_name: :desc)
    when "purpose_asc"
      order(:purpose)
    when "purpose_desc"
      order(purpose: :desc)
    when "department_asc"
      order(:department)
    when "department_desc"
      order(department: :desc)
    when "items_asc"
      order(checkout_items_count: :asc)
    when "items_desc"
      order(checkout_items_count: :desc)
    when "created_by_asc"
      joins(:user).order("users.email ASC")
    when "created_by_desc"
      joins(:user).order("users.email DESC")
    when "date_asc"
      order(created_at: :asc)
    else
      order(created_at: :desc)
    end
  }

  def recipient_full_name
    "#{recipient_first_name.humanize} #{recipient_last_name.humanize}"
  end
end
