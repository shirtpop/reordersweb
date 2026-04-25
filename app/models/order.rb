class Order < ApplicationRecord
  belongs_to :client
  belongs_to :catalog, optional: true
  belongs_to :ordered_by, class_name: "User", optional: true
  belongs_to :received_by, class_name: "User", optional: true
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
  scope :pending_receipt, -> {
    where.not(status: %w[cart received cancelled])
      .where(received_at: nil)
      .where("delivery_date < ?", Date.current)
  }

  scope :search_by_keyword, ->(keyword) {
    joins(:client, order_items: :product)
      .left_joins(:catalog)
      .where("clients.company_name ILIKE :keyword OR
              clients.personal_name ILIKE :keyword OR
              catalogs.name ILIKE :keyword OR
              products.name ILIKE :keyword", keyword: "%#{keyword}%")
  }

  validates :order_items, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :total_quantity, numericality: { greater_than_or_equal_to: 0 }

  accepts_nested_attributes_for :order_items, allow_destroy: true

  before_create :set_shipped_address
  before_create :set_order_number
  before_save :set_submitted_at
  after_commit :send_notifications, if: -> { status_submitted? }

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

  def set_order_number
    self.class.transaction do
      # Advisory lock scoped to this transaction prevents concurrent duplicates
      self.class.connection.execute("SELECT pg_advisory_xact_lock(hashtext('order_number_generation'))")
      now = Time.current
      month_start = now.beginning_of_month
      month_end = now.end_of_month
      count = self.class.where(created_at: month_start..month_end).count
      seq = (count + 1).to_s.rjust(4, "0")
      self.order_number = "O#{now.strftime('%Y%m%d')}#{seq}"
    end
  end

  def set_shipped_address
    self.shipped_to_id = client&.shipping_address_id
  end

  def set_submitted_at
    # Set submitted_at when order transitions from cart to submitted status
    if status_changed? && !status_cart? && status_was == "cart" && submitted_at.nil?
      self.submitted_at = Time.current
    end
  end
end
