module Orders
  class Creator
    attr_reader :order

    def initialize(order:)
      @order = order
    end

    def call!
      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback if @order.errors.any?

        calculator = Orders::Calculator.new(order: @order)
        @order.total_quantity = calculator.total_quantity
        @order.price = calculator.total_price

        @order.save!
      end
      @order
    rescue ActiveRecord::RecordInvalid
      @order
    end

    def success?
      @order.persisted? && @order.errors.empty?
    end
  end
end
