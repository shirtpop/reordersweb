class Client::InventoryMovement < ApplicationRecord
  INCREASE_MOVEMENTS = [ :stock_in, :return, :restock, :delivered_in ]
  DECREASE_MOVEMENTS = [ :stock_out, :damaged, :missing ]
  ALL_MOVEMENTS = INCREASE_MOVEMENTS + DECREASE_MOVEMENTS

  enum :movement_type, {
    stock_in: "stock_in",
    return: "return",
    restock: "restock",
    delivered_in: "delivered_in",

    stock_out: "stock_out",
    damaged: "damaged",
    missing: "missing"
  }, prefix: false, default: :stock_in

  store_accessor :metadata, :employee_email, :employee_name

  belongs_to :client_inventory, foreign_key: :client_inventory_id, class_name: "Client::Inventory"
  belongs_to :order_item, optional: true
  belongs_to :user
  belongs_to :client_checkout, optional: true, foreign_key: :client_checkout_id, class_name: "Client::Checkout"

  scope :stock_increase, -> { where(movement_type: INCREASE_MOVEMENTS) }
  scope :stock_decrease, -> { where(movement_type: DECREASE_MOVEMENTS) }
end
