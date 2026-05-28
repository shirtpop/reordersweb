class Client::Checkout < ApplicationRecord
  belongs_to :client
  belongs_to :user

  has_many :inventory_movements, class_name: "Client::InventoryMovement", dependent: :nullify, foreign_key: :client_checkout_id
  has_many :checkout_items, class_name: "Client::CheckoutItem", foreign_key: :client_checkout_id, dependent: :destroy

  enum :status, { draft: "draft", confirmed: "confirmed" }, default: :confirmed

  validates :recipient_email, :recipient_first_name, :recipient_last_name, presence: true, if: :confirmed?
  validates :recipient_email, format: { with: URI::MailTo::EMAIL_REGEXP }, if: :confirmed?
  validates :inventory_movements, presence: { message: "at least one item must be added to the checkout" }, if: :confirmed?

  scope :search_by_name, ->(name) {
    where("#{table_name}.recipient_email ILIKE :name OR
          #{table_name}.recipient_first_name ILIKE :name OR
          #{table_name}.recipient_last_name ILIKE :name",
          name: "%#{sanitize_sql_like(name)}%")
  }

  accepts_nested_attributes_for :inventory_movements, allow_destroy: true

  before_save :set_user_for_movements

  def recipient_full_name
    "#{recipient_first_name.humanize} #{recipient_last_name.humanize}"
  end

  private

  def set_user_for_movements
    inventory_movements.each do |movement|
      movement.user = user if movement.user_id.blank?
      movement.quantity = -movement.quantity.abs if movement.movement_type == "stock_out"
    end
  end
end
