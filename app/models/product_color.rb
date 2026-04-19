class ProductColor < ApplicationRecord
  belongs_to :product

  has_many :product_color_images, dependent: :destroy

  validates :name, presence: true

  after_create :create_angle_images

  private

  def create_angle_images
    ProductColorImage.angles.each_key do |angle|
      product_color_images.find_or_create_by!(angle: angle)
    end
  end
end
