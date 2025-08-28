module Orders
  class Creator
    attr_reader :order

    def initialize(order:)
      @order = order
    end

    def call!
      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback if @order.errors.any?

        calculate_total_quantity
        calculate_price

        @order.save!
      end
      @order
    rescue ActiveRecord::RecordInvalid
      @order
    end

    def success?
      @order.persisted? && @order.errors.empty?
    end

    private

    def products
      @products ||= Product.where(id: @order.order_items.map(&:product_id).uniq).index_by(&:id)
    end

    def calculate_total_quantity
      @order.total_quantity = @order.order_items.sum(&:quantity)
    end

    def calculate_price
      total_price = 0
      @order.order_items.group_by(&:product_id).each do |product_id, items|
        product = products[product_id]
        total_price += price_for(product, items.sum(&:quantity)).to_f * items.sum(&:quantity)
      end
      @order.price = total_price
    end

    def price_for(product, qty)
      return product.base_price.to_i unless product.bulk_prices

      applicable_prices = product.bulk_prices
        .select { |bp| bp["qty"].to_i <= qty }
        .map { |bp| bp["price"].to_f }

      applicable_prices.min || product.base_price
    end
  end
end
