# frozen_string_literal: true

module Checkouts
  class Creator
    class Error < StandardError; end
    class CheckoutCreationError < Error; end
    class StockUpdateError < Error; end

    attr_reader :checkout, :user

    def initialize(user:, checkout:)
      @user = user
      @checkout = checkout
    end

    def call!
      validate_items!
      validate_stock!

      ActiveRecord::Base.transaction do
        begin
          set_user_and_status
          checkout.save!

          checkout.checkout_items.each do |item|
            inventory = item.client_inventory
            raise StockUpdateError, "Missing inventory for item #{item.id}" unless inventory

            inventory.with_lock do
              raise StockUpdateError, "Insufficient stock for #{inventory.id}" if inventory.quantity < item.quantity

              inventory.decrement!(:quantity, item.quantity)
            end

            checkout.inventory_movements.create!(
              client_inventory: inventory,
              quantity: -item.quantity.abs,
              movement_type: :stock_out,
              user: user
            )
          end

          @checkout
        rescue ActiveRecord::RecordInvalid
          raise CheckoutCreationError, "Failed to create checkout: #{checkout.errors.full_messages.join(', ')}"
        end
      end
    end

    def success?
      checkout.persisted? && checkout.confirmed? && checkout.errors.empty?
    end

    private

    def validate_items!
      raise CheckoutCreationError, "No items in checkout" if checkout.checkout_items.empty?
    end

    def validate_stock!
      checkout.checkout_items.each do |item|
        inventory = item.client_inventory
        raise StockUpdateError, "Missing inventory for item #{item.id}" unless inventory
        raise StockUpdateError, "Insufficient stock for #{inventory.id}" if inventory.quantity < item.quantity
      end
    end

    def set_user_and_status
      checkout.user = user
      checkout.status = :confirmed
    end
  end
end
