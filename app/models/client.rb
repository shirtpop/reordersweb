class Client < ApplicationRecord
  include HasDriveFiles

  belongs_to :address, optional: true
  belongs_to :shipping_address, class_name: "Address", optional: true

  has_many :users, inverse_of: :client, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :catalogs, dependent: :destroy
  has_many :client_products, class_name: "Client::Product", dependent: :destroy
  has_many :checkouts, class_name: "Client::Checkout", dependent: :destroy
  has_many :product_variants, class_name: "Client::ProductVariant", through: :client_products
  has_many :inventories, class_name: "Client::Inventory", dependent: :destroy
  has_many :inventory_movements, through: :inventories, source: :inventory_movements

  validates :company_name, :personal_name, :phone_number, presence: true

  scope :search_by_name, ->(query) {
    sanitized_query = "%#{sanitize_sql_like(query)}%"
    where("#{table_name}.company_name ILIKE ?", sanitized_query)
    .or(where("#{table_name}.personal_name ILIKE ?", sanitized_query))
  }

  accepts_nested_attributes_for :address
  accepts_nested_attributes_for :shipping_address
  accepts_nested_attributes_for :users, allow_destroy: true

  def default_catalog
    catalogs.find_or_create_by!(name: "Default Catalog") do |catalog|
      catalog.status = :active
    end
  end

  def assigned_products
    ::Product.joins(:catalogs_products).where(catalogs_products: { catalog_id: catalogs.select(:id) }).distinct
  end

  def setup_complete?
    address.present? &&
      shipping_address.present? &&
      users.any? &&
      assigned_products.any? &&
      catalogs.active.any?
  end

  def setup_steps
    {
      client_created: persisted?,
      billing_address: address.present?,
      shipping_address: shipping_address.present?,
      user_created: users.any?,
      products_assigned: assigned_products.any?,
      catalog_active: catalogs.active.any?
    }
  end

  def setup_progress
    steps = setup_steps
    completed = steps.values.count(true)
    total = steps.size
    ((completed.to_f / total) * 100).round
  end
end
