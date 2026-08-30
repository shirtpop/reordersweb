class Client::InventoryMovement < ApplicationRecord
  enum :movement_type, { add: "add", subtract: "subtract" }, prefix: false, default: :add

  store_accessor :metadata, :employee_email, :employee_name

  belongs_to :client_inventory, foreign_key: :client_inventory_id, class_name: "Client::Inventory"
  belongs_to :order_item, optional: true
  belongs_to :user
  belongs_to :client_checkout, optional: true, foreign_key: :client_checkout_id, class_name: "Client::Checkout"

  validates :quantity, numericality: { greater_than: 0 }

  after_create :apply_to_inventory!
  after_commit :notify_low_stock, on: :create

  def signed_quantity
    add? ? quantity : -quantity
  end

  private

  def apply_to_inventory!
    client_inventory.with_lock do
      previous_quantity = client_inventory.quantity
      client_inventory.increment!(:quantity, signed_quantity)
      @crossed_into_low_stock = crossed_into_low_stock?(previous_quantity, client_inventory.quantity)
    end
  end

  def crossed_into_low_stock?(previous_quantity, new_quantity)
    threshold = client_inventory.minimum_quantity
    threshold.positive? && previous_quantity > threshold && new_quantity <= threshold
  end

  def notify_low_stock
    Inventories::LowStockNotifier.new(client_inventory).call if @crossed_into_low_stock
  end
end
