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
      ActiveRecord::Base.transaction do
        begin
          set_user_and_movement_type
          checkout.save!

          checkout.inventory_movements.each do |movement|
            inventory = movement.client_inventory
            raise StockUpdateError, "Missing inventory for movement #{movement.id}" unless inventory

            inventory.with_lock do
              raise StockUpdateError, "Insufficient stock for #{inventory.id}" if inventory.quantity < movement.quantity
              inventory.decrement!(:quantity, movement.quantity)
            end
          end

          @checkout
        rescue ActiveRecord::RecordInvalid
          @checkout
        end
      end
    end

    def success?
      checkout.persisted? && checkout.errors.empty?
    end

    private

    def set_user_and_movement_type
      checkout.user = user
      checkout.inventory_movements.each do |movement|
        movement.user = user
        movement.movement_type = :stock_out
      end
    end
  end
end
