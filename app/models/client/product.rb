class Client::Product < ApplicationRecord
  include HasDriveFiles

  belongs_to :client
  belongs_to :admin_product, class_name: "Product", optional: true, foreign_key: "product_id"

  has_many :product_variants, class_name: "Client::ProductVariant", foreign_key: "client_product_id", dependent: :destroy

  validates :name, presence: true
  validate :validate_max_drive_files

  after_create_commit :copy_drive_files

  has_rich_text :description

  self.max_drive_files = 2

  accepts_nested_attributes_for :product_variants, allow_destroy: true

  scope :search_by_name, ->(name) {
    where("#{table_name}.name ILIKE ?", "%#{sanitize_sql_like(name)}%")
  }

  accepts_nested_attributes_for :product_variants

  private

  def copy_drive_files
    return if product_id.blank?

    admin_product.drive_files.each do |drive_file|
      GoogleDrive::Copier.new(file: drive_file, attachable: self).call!
    end
  end
end
