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

        color_mapping = build_color_mapping(duplicated_product)
        duplicated_product.save!

        duplicate_drive_files(duplicated_product)
        copy_color_drive_files(color_mapping)

        duplicated_product
      rescue ActiveRecord::RecordInvalid, GoogleDrive::Copier::CopyError => e
        raise DuplicateError, e.message
      end
    end

    private

    def build_color_mapping(duplicated_product)
      @product.product_colors.each_with_object({}) do |color, mapping|
        new_color = duplicated_product.product_colors.build(
          color.attributes.except("id", "product_id", "created_at", "updated_at")
        )
        mapping[color] = new_color
      end
    end

    def duplicate_drive_files(duplicated_product)
      @product.drive_files.each do |drive_file|
        GoogleDrive::Copier.new(file: drive_file, attachable: duplicated_product).call!
      end
    end

    def copy_color_drive_files(color_mapping)
      color_mapping.each do |original_color, new_color|
        duplicate_color_images(original_color, new_color)
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
