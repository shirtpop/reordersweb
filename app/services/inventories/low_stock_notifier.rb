# frozen_string_literal: true

module Inventories
  class LowStockNotifier
    def initialize(client_inventory)
      @client_inventory = client_inventory
    end

    def call
      return unless admin_linked?
      return unless recipients?

      LowStockMailer.with(client_inventory_id: client_inventory.id).low_stock_alert.deliver_later
    end

    private

    attr_reader :client_inventory

    def admin_linked?
      client_inventory.client_product_variant.client_product.product_id.present?
    end

    def recipients?
      client_inventory.client.users.role_client.where(active: true).exists?
    end
  end
end
