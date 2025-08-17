module Products
  class Destroyer
    class DeleteError < StandardError; end

    def initialize(product:)
      @product = product
    end

    def call!
      ActiveRecord::Base.transaction do
        @product.destroy!
      end
    rescue ActiveRecord::RecordNotFound, GoogleDrive::Errors::DeleteError => e
      raise DeleteError, "Failed to delete product or associated drive files: #{e.message}"
    end
  end
end