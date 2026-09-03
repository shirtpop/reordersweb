# frozen_string_literal: true

require "csv"

module Checkouts
  class CsvExporter
    HEADERS = [
      "Recipient", "Purpose", "Department", "Created By", "Date",
      "Product", "SKU", "Color", "Size", "Quantity"
    ].freeze

    def initialize(checkouts)
      @checkouts = checkouts
    end

    def call
      CSV.generate(headers: true) do |csv|
        csv << HEADERS
        @checkouts.each do |checkout|
          checkout_row = [
            checkout.recipient_full_name,
            checkout.purpose,
            checkout.department,
            checkout.user.email,
            checkout.created_at.strftime("%Y-%m-%d %H:%M")
          ]

          if checkout.inventory_movements.empty?
            csv << checkout_row + [ nil, nil, nil, nil, nil ]
          else
            checkout.inventory_movements.each do |movement|
              variant = movement.client_inventory.client_product_variant
              product = variant.client_product

              csv << checkout_row + [
                product.name,
                variant.sku,
                variant.color || "N/A",
                variant.size || "N/A",
                movement.quantity.abs
              ]
            end
          end
        end
      end
    end
  end
end
