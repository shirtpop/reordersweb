class ProductColorImage < ApplicationRecord
  include HasDriveFiles

  belongs_to :product_color

  enum :angle, { front: "front", back: "back", left: "left", right: "right" }

  validates :angle, presence: true, uniqueness: { scope: :product_color_id }

  self.max_drive_files = 1

  def drive_file
    drive_files.first
  end
end
