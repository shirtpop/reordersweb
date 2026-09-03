class Client::Product < ApplicationRecord
  include HasDriveFiles

  belongs_to :client
  belongs_to :admin_product, class_name: "Product", optional: true, foreign_key: "product_id"

  has_many :product_variants, class_name: "Client::ProductVariant", foreign_key: "client_product_id", dependent: :destroy, inverse_of: :client_product

  validates :name, presence: true
  validates :product_id, uniqueness: { scope: :client_id }, allow_nil: true
  validate :validate_max_drive_files

  after_create_commit :copy_drive_files

  has_rich_text :description

  self.max_drive_files = 2

  accepts_nested_attributes_for :product_variants, allow_destroy: true

  scope :search_by_name, ->(name) {
    where("#{table_name}.name ILIKE ?", "%#{sanitize_sql_like(name)}%")
  }

  # Counts of records a delete would cascade through. Computed on demand (not eagerly),
  # since this only matters when the delete confirmation is actually opened.
  def delete_impact
    inventory_ids = product_variants.joins(:inventory).select("client_inventories.id")

    {
      inventory_movements: Client::InventoryMovement.where(client_inventory_id: inventory_ids).count,
      checkout_items: Client::CheckoutItem.where(client_inventory_id: inventory_ids).count
    }
  end

  # An active catalog carrying the linked admin product — nil if there's no
  # admin_product link or it's no longer assigned to any catalog this client can
  # browse. storefront_product_path requires a catalog_id, so this is what makes a
  # "reorder this" link resolvable instead of a dead/broken one.
  def reorder_catalog
    client.catalogs_for_product(product_id).first
  end

  private

  def copy_drive_files
    return if product_id.blank?

    admin_product.drive_files.each do |drive_file|
      GoogleDrive::Copier.new(file: drive_file, attachable: self).call!
    end
  end
end
