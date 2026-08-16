module GoogleDrive
  class DeleteFileJob < ApplicationJob
    retry_on GoogleDrive::Errors::DeleteError, wait: :polynomially_longer, attempts: 5

    def perform(drive_file_id)
      GoogleDrive::DriveService.delete_file(drive_file_id)
    end
  end
end
