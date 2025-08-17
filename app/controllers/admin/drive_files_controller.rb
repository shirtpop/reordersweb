module Admin
  class DriveFilesController < BaseController
    before_action :set_attachable
    before_action :set_drive_file, only: [:destroy]

    ALLOWED_ATTACHABLE_TYPES = %w[Product Client].freeze

    def create
      drive_file = GoogleDrive::Uploader.new(file: drive_file_params[:file], attachable: @attachable).call!

      render turbo_stream: turbo_stream.replace(
            "images_container_#{@attachable.class.name.downcase}_#{@attachable.id}",
            partial: 'shared/images_list',
            locals: { attachable: @attachable }
          )
    rescue GoogleDrive::Uploader::UploadError => e
      render turbo_stream: turbo_stream.replace(
            "images_container_#{@attachable.class.name.downcase}_#{@attachable.id}",
            partial: 'shared/error_message',
            locals: { message: 'Failed to upload file: ' + @drive_file.errors.full_messages.join(', ') }
          )
    end

    def destroy
      @drive_file.destroy!
      render turbo_stream: [
          turbo_stream.remove("drive_file_#{@drive_file.id}"),
          turbo_stream.replace(
            "images_container_#{@attachable.class.name.downcase}_#{@attachable.id}",
            partial: 'shared/images_list',
            locals: { attachable: @attachable }
          )
        ]
    rescue ActiveRecord::RecordNotFound, GoogleDrive::Errors::DeleteError => e
      render turbo_stream: turbo_stream.replace(
            "images_container_#{@attachable.class.name.downcase}_#{@attachable.id}",
            partial: 'shared/error_message',
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
  end
end
