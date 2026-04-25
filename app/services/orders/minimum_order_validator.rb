module Orders
  class MinimumOrderValidator
    # Use when passing synthetic items (e.g. simulating a quantity change before saving)
    Item = Struct.new(:product, :color, :quantity)

    def initialize(order_items:)
      @order_items = order_items
    end

    def violations
      result = []

      @order_items.group_by(&:product).each do |product, items|
        ordered_qty = items.group_by(&:color)
                           .transform_values { |rows| rows.sum(&:quantity) }

        product_min = product.minimum_order.to_i

        product.product_colors.each do |pc|
          qty       = ordered_qty[pc.name] || 0
          color_min = pc.minimum_order.to_i

          if color_min > 0
            # Required color — must be ordered and meet its own minimum
            if qty < color_min
              result << "#{product.name} – #{pc.name}: minimum is #{color_min} units (#{qty} selected)."
            end
          elsif product_min > 0 && qty > 0 && qty < product_min
            # Optional color — if ordered, must meet the product minimum run size
            result << "#{product.name} – #{pc.name}: minimum per color is #{product_min} units (#{qty} selected)."
          end
        end

        # Total quantity must also meet the product minimum
        total = ordered_qty.values.sum
        if product_min > 0 && total < product_min
          result << "#{product.name}: total minimum order is #{product_min} units (#{total} selected)."
        end
      end

      result
    end

    def valid?
      violations.empty?
    end
  end
end
