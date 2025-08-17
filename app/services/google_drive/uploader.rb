module GoogleDrive
  class Uploader
    class UploadError < Errors::UploadError; end

    def initialize(file:, attachable:)
      @file = file
      @attachable = attachable
    end

    def call!
      raise UploadError, "File is not present" unless @file.present?

      drive_file_id = DriveService.upload_file(io: @file.tempfile,
        filename: @file.original_filename,
        mime_type: @file.content_type)

      @attachable.drive_files.create!(
          drive_file_id: drive_file_id,
          filename: @file.original_filename,
          mime_type: @file.content_type
        )
    rescue ActiveRecord::RecordInvalid, GoogleDrive::Errors::UploadError => e
      raise UploadError, "Failed to upload file: #{e.record.errors.full_messages.join(', ')}"
    end
  end
end