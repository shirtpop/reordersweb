class Notification < ApplicationRecord
  READ_RETENTION = 3.days

  belongs_to :recipient, class_name: "User"
  belongs_to :notifiable, polymorphic: true

  enum :kind, {
    order_processed: "order_processed",
    low_stock: "low_stock",
    out_of_stock: "out_of_stock"
  }, prefix: true

  validates :title, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent_first, -> { order(created_at: :desc) }
  scope :expired_read, -> { read.where(read_at: ...READ_RETENTION.ago) }

  after_create_commit :broadcast_created

  def self.prune_expired_read!
    expired_read.delete_all
  end

  def self.broadcast_unread_count_for(recipient)
    Turbo::StreamsChannel.broadcast_replace_to [ recipient, :notifications ],
      target: "notification-badge",
      partial: "notifications/badge",
      locals: { count: recipient.notifications.unread.count }
  end

  def read? = read_at.present?

  def url
    case notifiable
    when Order
      Rails.application.routes.url_helpers.order_path(notifiable)
    when Client::Inventory
      Rails.application.routes.url_helpers.inventories_path
    end
  end

  private

  def broadcast_created
    broadcast_prepend_to [ recipient, :notifications ],
      target: "notifications-list",
      partial: "notifications/notification",
      locals: { notification: self }
    self.class.broadcast_unread_count_for(recipient)
  end
end
