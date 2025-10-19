module Orders
  class Receiver
    class Error < StandardError; end
    class InvalidRecordError < Error; end
    class RecordNotFoundError < Error; end
    class InventoryLockError < Error; end
    class BusinessRuleError < Error; end

    def self.call!(order:, user:)
      new(order:, user:).call!
    end

    attr_reader :order, :user

    def initialize(order:, user:)
      @order = order
      @user = user
    end

    def call!
      raise BusinessRuleError, "Order already received" if order.received_at.present?

      ActiveRecord::Base.transaction do
        preload_caches!

        order.order_items.each do |item|
          client_product = find_or_create_client_product(item)
          client_variant = find_or_create_client_variant(client_product, item)
          inventory = find_or_create_inventory(client_variant)

          inventory.with_lock do
            inventory.inventory_movements.create!(
              user: user,
              movement_type: :delivered_in,
              quantity: item.quantity,
              order_item: item
            )

            inventory.increment!(:quantity, item.quantity)
          end
        end

        mark_order_as_received!
      end
    rescue ActiveRecord::RecordInvalid => e
      raise InvalidRecordError, e.message
    rescue ActiveRecord::RecordNotFound => e
      raise RecordNotFoundError, e.message
    rescue ActiveRecord::LockWaitTimeout, ActiveRecord::Deadlocked => e
      raise InventoryLockError, "Concurrent inventory modification: #{e.message}"
    end

    private

    def preload_caches!
      @client_products = Client::Product
        .where(client_id: order.client_id, product_id: order.order_items.map(&:product_id))
        .index_by(&:product_id)

      client_product_ids = @client_products.values.map(&:id)
      @client_variants = Client::ProductVariant
        .where(client_product_id: client_product_ids)
        .group_by(&:client_product_id)

      @inventories = Client::Inventory
        .where(client_id: order.client_id, client_product_variant_id: @client_variants.values.flatten.map(&:id))
        .index_by(&:client_product_variant_id)
    end

    def find_or_create_client_product(item)
      @client_products[item.product_id] ||= Client::Product.create_with(
        name: item.product.name
      ).find_or_create_by!(
        client_id: order.client_id,
        product_id: item.product_id
      )
    end

    def find_or_create_client_variant(client_product, item)
      @client_variants[client_product.id] ||= []
      variant = @client_variants[client_product.id].find { |v| v.color == item.color && v.size == item.size }

      unless variant
        variant = Client::ProductVariant.create!(
          client_product_id: client_product.id,
          color: item.color,
          size: item.size
        )
        @client_variants[client_product.id] << variant
      end

      variant
    end

    def find_or_create_inventory(client_variant)
      @inventories[client_variant.id] ||= Client::Inventory.find_or_create_by!(
        client_id: order.client_id,
        client_product_variant_id: client_variant.id
      )
    end

    def mark_order_as_received!
      order.update!(
        received_at: Time.current,
        received_by_id: user.id
      )
    end
  end
end
