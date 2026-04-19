class ProductColorImage < ApplicationRecord
  include HasDriveFiles

  belongs_to :product_color

  enum :angle, { front: 0, back: 1, left: 2, right: 3 }

  validates :angle, presence: true, uniqueness: { scope: :product_color_id }

  self.max_drive_files = 1

  def drive_file
    drive_files.first
  end
end
