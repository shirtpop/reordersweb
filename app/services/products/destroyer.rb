module Products
  class Destroyer
    class DeleteError < StandardError; end

    def initialize(product:)
      @product = product
    end

    def call!
      ActiveRecord::Base.transaction do
        CatalogsProduct.where(product_id: @product.id).delete_all
        @product.destroy!
      end
    rescue GoogleDrive::Errors::DeleteError => e
      raise DeleteError, "Failed to delete Google Drive files: #{e.message}"
    rescue ActiveRecord::RecordNotFound, ActiveRecord::InvalidForeignKey => e
      raise DeleteError, "Failed to delete product or associated records: #{e.message}"
    end
  end
end
