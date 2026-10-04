# frozen_string_literal: true

require "prawn"
require "barby"
require "barby/barcode/code_128"
require "barby/outputter/prawn_outputter"

module Inventories
  # Renders printable A4 barcode sheets (3 columns), grouped by "Product - Color".
  class BarcodesPdf
    COLUMNS = 3
    MARGIN = 28
    GUTTER = 10
    CARD_HEIGHT = 92
    CARD_PADDING = 6
    HEADING_HEIGHT = 26

    def initialize(products:)
      @products = products
    end

    def call
      @pdf = Prawn::Document.new(page_size: "A4", margin: MARGIN)
      groups.each { |title, variants| render_group(title, variants) }
      @pdf.text "No products found", align: :center if groups.empty?
      @pdf.render
    end

    private

    attr_reader :products

    def groups
      @groups ||= products.flat_map do |product|
        product.product_variants.group_by { |v| v.color.to_s.strip }.map do |color, variants|
          [ [ product.name, color.presence ].compact.join(" - "), variants.sort_by { |v| v.size.to_s } ]
        end
      end.reject { |_, variants| variants.empty? }
    end

    def card_width
      @card_width ||= (@pdf.bounds.width - GUTTER * (COLUMNS - 1)) / COLUMNS
    end

    def render_group(title, variants)
      variants.each_slice(COLUMNS).with_index do |row, index|
        # Keep the heading together with its first row of labels.
        needed = (index.zero? ? HEADING_HEIGHT : 0) + CARD_HEIGHT
        @pdf.start_new_page if @pdf.cursor < needed
        render_heading(title) if index.zero?

        top = @pdf.cursor
        row.each_with_index do |variant, col|
          render_card(variant, x: col * (card_width + GUTTER), top: top)
        end
        # bounding_box already advanced the cursor past the row.
        @pdf.move_down GUTTER
      end
      @pdf.move_down GUTTER
    end

    def render_heading(title)
      @pdf.font("Helvetica", style: :bold, size: 12) { @pdf.text safe(title) }
      @pdf.stroke_horizontal_rule
      @pdf.move_down HEADING_HEIGHT - 16
    end

    def render_card(variant, x:, top:)
      @pdf.bounding_box([ x, top ], width: card_width, height: CARD_HEIGHT) do
        @pdf.stroke_bounds
        @pdf.bounding_box([ CARD_PADDING, CARD_HEIGHT - CARD_PADDING ],
                          width: card_width - CARD_PADDING * 2, height: CARD_HEIGHT - CARD_PADDING * 2) do
          @pdf.font("Helvetica", size: 9) { @pdf.text(variant.size.present? ? "Size: #{safe(variant.size)}" : " ", align: :center) }
          draw_barcode(variant.sku, width: card_width - CARD_PADDING * 2)
          @pdf.font("Courier", style: :bold, size: 8) do
            @pdf.text_box "SKU: #{safe(variant.sku)}", at: [ 0, 14 ], width: card_width - CARD_PADDING * 2,
                          height: 12, align: :center, overflow: :shrink_to_fit
          end
        end
      end
    end

    def draw_barcode(sku, width:)
      return if sku.blank?

      barcode = Barby::Code128B.new(sku)
      xdim = width / barcode.encoding.length
      barcode.annotate_pdf(@pdf, x: @pdf.bounds.left, y: @pdf.bounds.bottom + 18, height: 36, xdim: xdim)
    rescue ArgumentError
      # SKU contains characters Code128B cannot encode; the printed SKU text remains.
    end

    # Built-in PDF fonts only cover Windows-1252.
    def safe(text)
      text.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?").encode("UTF-8")
    end
  end
end
