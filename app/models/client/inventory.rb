class Client::Inventory < ApplicationRecord
  belongs_to :client, class_name: "Client"
  belongs_to :client_product_variant, class_name: "Client::ProductVariant"

  has_many :inventory_movements, class_name: "Client::InventoryMovement", dependent: :destroy, foreign_key: :client_inventory_id

  scope :search_by_keyword, ->(keyword) {
    joins(client_product_variant: :client_product)
      .where(
        "client_products.name ILIKE ? OR client_product_variants.color ILIKE ? OR client_product_variants.size ILIKE ? OR client_product_variants.sku ILIKE ?",
        "%#{keyword}%", "%#{keyword}%", "%#{keyword}%", "%#{keyword}%"
      )
  }

  scope :in_stock, -> { where("quantity > 0") }
  scope :low_stock, ->(threshold = 10) { where("quantity > 0 AND quantity <= ?", threshold) }
  scope :out_of_stock, -> { where(quantity: 0) }
end
