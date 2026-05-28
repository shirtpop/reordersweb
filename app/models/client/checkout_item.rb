class Client::CheckoutItem < ApplicationRecord
  belongs_to :client_checkout, class_name: "Client::Checkout", foreign_key: :client_checkout_id
  belongs_to :client_inventory, class_name: "Client::Inventory", foreign_key: :client_inventory_id

  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
end
