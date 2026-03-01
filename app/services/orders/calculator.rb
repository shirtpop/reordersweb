module Orders
  class Calculator
    attr_reader :order

    def initialize(order:)
      @order = order
    end

    # Calculate total quantity of all order items
    def total_quantity
      @order.order_items.sum(&:quantity)
    end

    # Calculate total price with bulk pricing applied
    def total_price
      total = 0

      @order.order_items.group_by(&:product).each do |product, items|
        product_quantity = items.sum(&:quantity)
        applicable_price = price_for_quantity(product, product_quantity)
        total += applicable_price * product_quantity
      end

      total
    end

    # Calculate breakdown by product (useful for order summary display)
    def breakdown
      @order.order_items.group_by(&:product).map do |product, items|
        product_quantity = items.sum(&:quantity)
        applicable_price = price_for_quantity(product, product_quantity)
        subtotal = applicable_price * product_quantity

        {
          product: product,
          quantity: product_quantity,
          unit_price: applicable_price,
          subtotal: subtotal,
          items: items
        }
      end
    end

    private

    # Determine applicable price based on quantity (base or bulk)
    def price_for_quantity(product, quantity)
      return product.base_price.to_f unless product.bulk_prices.present?

      # Find the highest quantity threshold that we meet or exceed
      applicable_prices = product.bulk_prices
        .select { |bp| bp["qty"].to_i <= quantity }
        .map { |bp| bp["price"].to_f }

      # Return the minimum price from applicable bulk prices, or base price if none apply
      applicable_prices.min || product.base_price.to_f
    end
  end
end
