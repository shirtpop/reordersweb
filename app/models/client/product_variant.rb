class Client::ProductVariant < ApplicationRecord
  belongs_to :client_product, class_name: "Client::Product", counter_cache: true, optional: true

  has_one :inventory, class_name: "Client::Inventory", dependent: :destroy, foreign_key: "client_product_variant_id"
  has_many :inventory_movements, through: :inventory

  scope :search_by_product_name, ->(query) {
    joins(:client_product)
      .where("client_products.name ILIKE ?", "%#{sanitize_sql_like(query)}%")
  }

  before_create :set_sku_if_blank

  private

  def set_sku_if_blank
    return if sku.present?

    product_prefix = client_product.name.strip[0..2].upcase.gsub(/[^A-Z0-9]/, "")
    color_part = color.to_s.strip.upcase.gsub(/[^A-Z0-9]/, "")
    size_part = size.to_s.strip.upcase.gsub(/[^A-Z0-9]/, "")
    random_hex = SecureRandom.hex(3).upcase

    self.sku = "#{product_prefix}-#{color_part}-#{size_part}-#{random_hex}"
  end
end
