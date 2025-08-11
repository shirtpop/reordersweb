class Product < ApplicationRecord
  SIZES = ['XXS', 'XS', 'S', 'M', 'L', 'XL', '2XL', '3XL', '4XL', '5XL', '6XL', '7XL', 'Single Size'].freeze

  validates :name, presence: true

  store_accessor :price_info, :minimum_order, :base_price, :bulk_prices

  scope :search_by_name, ->(name) {
    where("#{table_name}.name ILIKE ?", "%#{sanitize_sql_like(name)}%")
  }

  has_many :products_projects, dependent: :destroy
  has_many :projects, through: :products_projects

  has_rich_text :description

  def color_names
    Array(colors).map { |c| c["name"] }.join(", ")
  end
end
