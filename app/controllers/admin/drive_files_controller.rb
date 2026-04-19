module Admin
  class DriveFilesController < BaseController
    before_action :set_attachable
    before_action :set_drive_file, only: [ :destroy ]

    ALLOWED_ATTACHABLE_TYPES = %w[Product ProductColor ProductColorImage Client].freeze

    def create
      GoogleDrive::Uploader.new(file: drive_file_params[:file], attachable: @attachable).call!

      render turbo_stream: turbo_stream.replace(
            images_container_id,
            partial: images_list_partial,
            locals: images_locals
          )
    rescue GoogleDrive::Uploader::UploadError => e
      render turbo_stream: turbo_stream.replace(
            images_container_id,
            partial: "shared/error_message",
            locals: { message: "Failed to upload file: " + e.message }
          )
    end

    def destroy
      @drive_file.destroy!
      render turbo_stream: turbo_stream.replace(
            images_container_id,
            partial: images_list_partial,
            locals: images_locals
          )
    rescue ActiveRecord::RecordNotFound, GoogleDrive::Errors::DeleteError => e
      render turbo_stream: turbo_stream.replace(
            images_container_id,
            partial: "shared/error_message",
            locals: { message: e.message }
          )
    end

    private

    def drive_file_params
      params.permit(:file)
    end

    def set_attachable
      unless ALLOWED_ATTACHABLE_TYPES.include?(params[:attachable_type])
        raise ActionController::ParameterMissing, "Invalid attachable_type"
      end

      @attachable = params[:attachable_type].classify.constantize.find(params[:attachable_id])
    end

    def set_drive_file
      @drive_file = @attachable.drive_files.find(params[:id])
    end

    def images_container_id
      "images_container_#{@attachable.class.name.downcase}_#{@attachable.id}"
    end

    def images_list_partial
      @attachable.is_a?(ProductColorImage) ? "admin/products/color_image_slot_frame" : "shared/images_list"
    end

    def images_locals
      @attachable.is_a?(ProductColorImage) ? { color_image: @attachable } : { attachable: @attachable }
    end
  end
end
