class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :color, presence: true
  validates :size, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }

  def total_price
    product.base_price * quantity
  end
end
