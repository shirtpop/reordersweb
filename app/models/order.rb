class Order < ApplicationRecord
  belongs_to :client
  belongs_to :project, optional: true
  belongs_to :ordered_by, class_name: "User", optional: true
  belongs_to :shipped_to, class_name: "Address", optional: true

  has_many :order_items, dependent: :destroy

  # Order status enum
  enum :status, {
    cart: "cart",           # Draft order (items in cart, not submitted)
    submitted: "submitted",     # Submitted, awaiting processing
    processing: "processing",
    received: "received",   # Order received/completed
    cancelled: "cancelled"  # Cancelled order
  }, prefix: true

  # Scopes for filtering orders
  scope :submitted, -> { where.not(status: "cart") }  # Exclude cart/draft orders
  scope :in_cart, -> { status_cart }

  scope :search_by_keyword, ->(keyword) {
    joins(:client, :project, order_items: :product)
      .where("clients.company_name ILIKE :keyword OR
              clients.personal_name ILIKE :keyword OR
              projects.name ILIKE :keyword OR
              products.name ILIKE :keyword", keyword: "%#{keyword}%")
  }

  validates :order_items, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :total_quantity, numericality: { greater_than_or_equal_to: 0 }

  accepts_nested_attributes_for :order_items, allow_destroy: true

  before_create :set_shipped_address
  # Only send notifications for submitted orders, not cart/draft orders
  after_commit :send_notifications, on: :create, if: -> { status_submitted? || status_received? }

  def total_price
    order_items.sum { |item| item.total_price }
  end

  def received?
    !!received_at
  end

  private

  def send_notifications
    OrderMailer.with(order_id: self.id).client_confirmation.deliver_later
    OrderMailer.with(order_id: self.id).admin_notification.deliver_later
  end

  def set_shipped_address
    self.shipped_to_id = client&.shipping_address_id
  end
end
