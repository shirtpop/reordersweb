class Client::ProductVariant < ApplicationRecord
  belongs_to :client_product, class_name: "Client::Product"

  has_one :inventory, class_name: "Client::Inventory", dependent: :destroy, foreign_key: "client_product_variant_id"
  has_many :inventory_movements, through: :inventory
end
