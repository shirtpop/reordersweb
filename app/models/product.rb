class Product < ApplicationRecord
  include HasDriveFiles

  SIZES = [ "XXS", "XS", "S", "M", "L", "XL", "2XL", "3XL", "4XL", "5XL", "6XL", "7XL", "Single Size" ].freeze

  store_accessor :price_info, :minimum_order, :base_price, :bulk_prices

  scope :search_by_name, ->(name) {
    where("#{table_name}.name ILIKE ?", "%#{sanitize_sql_like(name)}%")
  }

  has_many :products_projects, dependent: :delete_all
  has_many :projects, through: :products_projects

  validates :name, presence: true
  validate :validate_bulk_prices

  has_rich_text :description

  def color_names
    Array(colors).map { |c| c["name"] }.join(", ")
  end

  private

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
