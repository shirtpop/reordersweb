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

    def call!
      CSV.generate(headers: true) do |csv|
        csv << HEADERS

        sorted_inventories.each do |inventory|
          csv << build_row(inventory)
        end
      end
    rescue => e
      raise ExportError, "Failed to export inventories: #{e.message}"
    end

    private

    attr_reader :inventories, :sort_by

    def sorted_inventories
      case sort_by
      when "product_name_asc"
        inventories.joins(client_product_variant: :client_product).order("client_products.name ASC")
      when "product_name_desc"
        inventories.joins(client_product_variant: :client_product).order("client_products.name DESC")
      when "quantity_asc"
        inventories.order(:quantity)
      when "quantity_desc"
        inventories.order(quantity: :desc)
      else
        inventories.order(:id)
      end
    end

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
        determine_status(inventory.quantity)
      ]
    end

    def determine_status(quantity)
      if quantity > 10
        "In Stock"
      elsif quantity > 0
        "Low Stock"
      else
        "Out of Stock"
      end
    end

    def strip_html_tags(text)
      ActionController::Base.helpers.strip_tags(text)
    end
  end
end
