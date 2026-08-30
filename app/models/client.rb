class Client < ApplicationRecord
  include HasDriveFiles

  belongs_to :address, optional: true
  belongs_to :shipping_address, class_name: "Address", optional: true
  belongs_to :parent, class_name: "Client", optional: true

  has_many :children, class_name: "Client", foreign_key: :parent_id, inverse_of: :parent, dependent: :restrict_with_error
  has_many :users, inverse_of: :client, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :catalogs, dependent: :destroy
  has_many :client_products, class_name: "Client::Product", dependent: :destroy
  has_many :checkouts, class_name: "Client::Checkout", dependent: :destroy
  has_many :product_variants, class_name: "Client::ProductVariant", through: :client_products
  has_many :inventories, class_name: "Client::Inventory", dependent: :destroy
  has_many :inventory_movements, through: :inventories, source: :inventory_movements
  has_many :users, inverse_of: :client, dependent: :destroy

  validates :company_name, :personal_name, :phone_number, presence: true
  validate :parent_hierarchy_is_a_single_level

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
    ::Product.joins(:catalogs_products).where(catalogs_products: { catalog_id: catalogs.active.select(:id) }).distinct
  end

  # Active catalogs this client can browse in the storefront: its own plus any linked
  # children's (a main account sees everything; a child only ever sees its own, since
  # its own `children` is always empty).
  def browsable_catalogs
    Catalog.active.ordered.where(client_id: [ id, *children.ids ])
  end

  # Active catalogs (belonging to this client or one of its children — matching
  # StorefrontController's visibility rules) that currently carry the given admin
  # product. A product can be assigned to more than one catalog, so this can return
  # several rows; callers that need a single link target should pick one explicitly.
  def catalogs_for_product(product_id)
    return Catalog.none if product_id.blank?

    browsable_catalogs
      .joins(:catalogs_products)
      .where(catalogs_products: { product_id: product_id })
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

  # Counts of records a delete would cascade through. Computed on demand (not eagerly),
  # since this only matters when the delete confirmation is actually opened.
  def delete_impact
    {
      users: users.count,
      orders: orders.count,
      catalogs: catalogs.count,
      client_products: client_products.count,
      checkouts: checkouts.count
    }
  end

  private

  def parent_hierarchy_is_a_single_level
    return if parent_id.blank?

    errors.add(:parent_id, "can't be set to itself") if parent_id == id
    errors.add(:parent_id, "can't be a client that already has linked child accounts") if children.any?
    errors.add(:parent_id, "can't be a client that is already linked under another parent") if parent&.parent_id.present?
  end
end
