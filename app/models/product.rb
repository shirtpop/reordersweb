class Product < ApplicationRecord
  include HasDriveFiles

  SIZES = [ "XXS", "XS", "S", "M", "L", "XL", "2XL", "3XL", "4XL", "5XL", "6XL", "7XL", "Single Size" ].freeze

  store_accessor :price_info, :minimum_order, :base_price, :bulk_prices

  scope :search_by_name, ->(name) {
    where("#{table_name}.name ILIKE ?", "%#{sanitize_sql_like(name)}%")
  }

  has_many :catalogs_products, dependent: :delete_all
  has_many :catalogs, through: :catalogs_products
  has_many :product_colors, dependent: :destroy

  accepts_nested_attributes_for :product_colors, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true
  validates :product_colors, presence: true
  validate :validate_bulk_prices
  validate :validate_max_drive_files
  validate :validate_minimum_order_matches_colors

  has_rich_text :description

  self.max_drive_files = 2

  def color_names
    product_colors.map(&:name).join(", ")
  end

  def minimum_order
    super || 0
  end

  def base_price
    super || 0.0
  end

  def bulk_prices
    super || []
  end

  private

  def validate_minimum_order_matches_colors
    active_colors = product_colors.reject(&:marked_for_destruction?)
    color_sum = active_colors.sum { |pc| pc.minimum_order.to_i }

    return if color_sum == 0 && minimum_order.to_i == 0

    if minimum_order.to_i != color_sum
      errors.add(:minimum_order, "must equal the sum of all color minimum orders (expected #{color_sum})")
    end
  end

  def validate_bulk_prices
    return if bulk_prices.blank?

    seen_qtys = []
    bulk_prices.each_with_index do |bp, i|
      qty  = bp["qty"].to_i
      price = bp["price"].to_f

      errors.add(:bulk_prices, "row ##{i + 1}: qty must be greater than minimum order") if qty <= minimum_order.to_i
      errors.add(:bulk_prices, "row ##{i + 1}: qty must be a positive integer") if qty <= 0
      errors.add(:bulk_prices, "row ##{i + 1}: price must be greater than 0") if price <= 0
      errors.add(:bulk_prices, "row ##{i + 1}: duplicate qty #{qty}") if seen_qtys.include?(qty)
      errors.add(:bulk_prices, "row ##{i + 1}: price should be lower than base price") if base_price.present? && price >= base_price.to_f

      seen_qtys << qty
    end
  end
end
