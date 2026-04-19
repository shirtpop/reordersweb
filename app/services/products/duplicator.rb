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
        duplicate_product_colors(duplicated_product)

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

    def duplicate_product_colors(duplicated_product)
      @product.product_colors.each do |color|
        new_color = color.dup
        new_color.product = duplicated_product
        new_color.save!
        color.drive_files.each do |drive_file|
          GoogleDrive::Copier.new(file: drive_file, attachable: new_color).call!
        end
        duplicate_color_images(color, new_color)
      end
    end

    def duplicate_color_images(original_color, new_color)
      original_color.product_color_images.each do |image|
        next unless image.drive_file

        new_image = new_color.product_color_images.find_by!(angle: image.angle)
        GoogleDrive::Copier.new(file: image.drive_file, attachable: new_image).call!
      end
    end
  end
end
