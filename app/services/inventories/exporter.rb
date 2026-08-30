# frozen_string_literal: true

require "csv"

module Inventories
  class Exporter
    class Error < StandardError; end
    class ExportError < Error; end

    HEADERS = [
      "Product Name",
      "Product Description",
      "Color",
      "Size",
      "SKU",
      "Quantity",
      "Status"
    ].freeze

    def initialize(inventories:, sort_by: nil)
      @inventories = inventories
      @sort_by = sort_by
    end

    STATUS_LABELS = {
      in_stock: "In Stock",
      low_stock: "Low Stock",
      out_of_stock: "Out of Stock"
    }.freeze

    def call!
      CSV.generate(headers: true) do |csv|
        csv << HEADERS

        inventories.sorted_by(sort_by).each do |inventory|
          csv << build_row(inventory)
        end
      end
    rescue => e
      raise ExportError, "Failed to export inventories: #{e.message}"
    end

    private

    attr_reader :inventories, :sort_by

    def build_row(inventory)
      variant = inventory.client_product_variant
      product = variant.client_product

      [
        product.name,
        strip_html_tags(product.description.to_s),
        variant.color.present? ? variant.color : "N/A",
        variant.size.present? ? variant.size : "N/A",
        variant.sku.present? ? variant.sku : "N/A",
        inventory.quantity,
        STATUS_LABELS.fetch(inventory.stock_status)
      ]
    end

    def strip_html_tags(text)
      ActionController::Base.helpers.strip_tags(text)
    end
  end
end
