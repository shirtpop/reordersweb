module Products
  class Destroyer
    class DeleteError < StandardError; end

    def initialize(product:)
      @product = product
    end

    def call!
      ActiveRecord::Base.transaction do
        ProductsProject.where(product_id: @product.id).delete_all

        begin
          @product.destroy!
        rescue GoogleDrive::Errors::DeleteError => e
          if e.message.include?("notFound: File not found")
            file_id = e.message[/[a-zA-Z0-9_-]{25,}/]
            @product.drive_files.find_by(drive_file_id: file_id)&.delete
            @product.delete
          else
            raise e
          end
        end
      end
    rescue GoogleDrive::Errors::DeleteError => e
      raise DeleteError, "Failed to delete Google Drive files: #{e.message}"
    rescue ActiveRecord::RecordNotFound, ActiveRecord::InvalidForeignKey => e
      raise DeleteError, "Failed to delete product or associated records: #{e.message}"
    end
  end
end
