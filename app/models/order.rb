class Order < ApplicationRecord
  
  belongs_to :client
  belongs_to :project

  has_many :order_items, dependent: :destroy

  scope :search_by_keyword, ->(keyword) {
    joins(:client, :project, order_items: :product)
      .where("clients.company_name ILIKE :keyword OR
              clients.personal_name ILIKE :keyword OR
              projects.name ILIKE :keyword OR
              products.name ILIKE :keyword", keyword: "%#{keyword}%")
  }

  validates :delivery_date, presence: true
  validates :order_items, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :total_quantity, numericality: { greater_than_or_equal_to: 0 }

  accepts_nested_attributes_for :order_items, allow_destroy: true

  def total_price
    order_items.sum { |item| item.total_price }
  end  
end
