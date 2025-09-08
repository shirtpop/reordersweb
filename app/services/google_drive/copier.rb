module GoogleDrive
  class Copier
    class CopyError < Errors::UploadError; end

    def initialize(file:, attachable:)
      @file = file
      @attachable = attachable
    end

    def call!
      raise CopyError, "Original file is not present" unless @file.present?

      copied_file_id = DriveService.copy_file(@file.drive_file_id, new_filename:)
      @attachable.drive_files.create!(
        drive_file_id: copied_file_id,
        filename: new_filename,
        mime_type: @file.mime_type
      )
    rescue ActiveRecord::RecordInvalid, GoogleDrive::Errors::UploadError => e
      raise CopyError, "Failed to copy file: #{e.record.errors.full_messages.join(', ')}"
    end

    private

    def new_filename
      @new_filename ||= "Copy of " + @file.filename
    end
  end
end
