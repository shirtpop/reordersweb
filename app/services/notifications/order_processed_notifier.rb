# frozen_string_literal: true

module Notifications
  class OrderProcessedNotifier < Base
    private

    def order = notifiable

    def recipients
      order.client.users.role_client.where(active: true)
    end

    def kind
      :order_processed
    end

    def title
      "Order #{order.order_number} is being processed"
    end

    def description
      "Your order from #{order.submitted_at&.to_date || order.created_at.to_date} is now being processed."
    end
  end
end
