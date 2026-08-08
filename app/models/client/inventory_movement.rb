class Client::InventoryMovement < ApplicationRecord
  enum :movement_type, { add: "add", subtract: "subtract" }, prefix: false, default: :add

  store_accessor :metadata, :employee_email, :employee_name

  belongs_to :client_inventory, foreign_key: :client_inventory_id, class_name: "Client::Inventory"
  belongs_to :order_item, optional: true
  belongs_to :user
  belongs_to :client_checkout, optional: true, foreign_key: :client_checkout_id, class_name: "Client::Checkout"

  validates :quantity, numericality: { greater_than: 0 }

  after_create :apply_to_inventory!

  def signed_quantity
    add? ? quantity : -quantity
  end

  private

  def apply_to_inventory!
    client_inventory.with_lock { client_inventory.increment!(:quantity, signed_quantity) }
  end
end
