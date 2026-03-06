module Clients
  class AssignProducts
    def initialize(client:, product_ids:)
      @client = client
      @product_ids = Array(product_ids).map(&:to_i).uniq
      @failed = false
    end

    def call!
      ActiveRecord::Base.transaction do
        catalog = @client.default_catalog
        current_ids = catalog.product_ids

        to_add = @product_ids - current_ids
        to_remove = current_ids - @product_ids

        CatalogsProduct.where(catalog: catalog, product_id: to_remove).delete_all if to_remove.any?

        to_add.each do |product_id|
          CatalogsProduct.create!(catalog: catalog, product_id: product_id)
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      @failed = true
      Rails.logger.error("AssignProducts failed: #{e.message}")
    end

    def success?
      !@failed
    end
  end
end
