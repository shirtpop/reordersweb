class Client::Inventory < ApplicationRecord
  belongs_to :client, class_name: "Client"
  belongs_to :client_product_variant, class_name: "Client::ProductVariant"

  has_many :inventory_movements, class_name: "Client::InventoryMovement", dependent: :destroy, foreign_key: :client_inventory_id
  has_many :checkout_items, class_name: "Client::CheckoutItem", dependent: :destroy, foreign_key: :client_inventory_id

  validates :minimum_quantity, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  scope :search_by_keyword, ->(keyword) {
    joins(client_product_variant: :client_product)
      .where(
        "client_products.name ILIKE ? OR client_product_variants.color ILIKE ? OR client_product_variants.size ILIKE ? OR client_product_variants.sku ILIKE ?",
        "%#{keyword}%", "%#{keyword}%", "%#{keyword}%", "%#{keyword}%"
      )
  }

  scope :in_stock, -> { where("quantity > 0") }
  scope :low_stock, -> { where("minimum_quantity > 0 AND quantity > 0 AND quantity <= minimum_quantity") }
  scope :out_of_stock, -> { where(quantity: 0) }

  scope :sorted_by, ->(sort_by) {
    case sort_by
    when "product_name_asc"
      joins(client_product_variant: :client_product).order("client_products.name ASC")
    when "product_name_desc"
      joins(client_product_variant: :client_product).order("client_products.name DESC")
    when "quantity_asc"
      order(:quantity)
    when "quantity_desc"
      order(quantity: :desc)
    else
      order(:id)
    end
  }

  def stock_status
    return :out_of_stock if quantity <= 0
    return :low_stock if minimum_quantity.positive? && quantity <= minimum_quantity

    :in_stock
  end
end
