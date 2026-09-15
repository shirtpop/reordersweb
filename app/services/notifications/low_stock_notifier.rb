# frozen_string_literal: true

module Notifications
  class LowStockNotifier < Base
    private

    def client_inventory = notifiable

    def variant = client_inventory.client_product_variant

    def product = variant.client_product

    def recipients
      client_inventory.client.users.role_client.where(active: true)
    end

    def kind
      client_inventory.stock_status
    end

    def title
      kind == :out_of_stock ? "#{product.name} is out of stock" : "#{product.name} is running low"
    end

    def description
      "#{product.name} (#{variant.color} / #{variant.size}) has #{client_inventory.quantity} unit(s) left."
    end
  end
end
