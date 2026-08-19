class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product
  belongs_to :product_color, optional: true

  has_many :inventory_movements, class_name: "Client::InventoryMovement", dependent: :destroy

  validates :color, presence: true
  validates :size, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }

  def total_price
    product.base_price * quantity
  end
end
