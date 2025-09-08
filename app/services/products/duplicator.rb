module Products
  class Duplicator
    class DuplicateError < StandardError; end

    def initialize(product:)
      @product = product
    end

    def call!
      begin
        duplicated_product = @product.dup
        duplicated_product.name = "Copy of " + @product.name
        duplicated_product.save!
        duplicate_drive_files(duplicated_product)

        duplicated_product
      rescue ActiveRecord::RecordInvalid, GoogleDrive::Copier::CopyError => e
        raise DuplicateError, e.message
      end
    end

    private

    def duplicate_drive_files(duplicated_product)
      @product.drive_files.each do |drive_file|
        GoogleDrive::Copier.new(file: drive_file, attachable: duplicated_product).call!
      end
    end
  end
end
