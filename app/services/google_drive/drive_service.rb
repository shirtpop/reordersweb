module GoogleDrive
  class DriveService
    # Scope is defined in each APIs.
    # ex) https://developers.google.com/drive/api/reference/rest/v3/files/create?hl=en#authorization-scopes
    SCOPE = [ "https://www.googleapis.com/auth/drive" ].freeze
    PERMISSION_TYPE = "anyone"
    PERMISSION_ROLE = "reader"

    class << self
      def drive_service
        @drive_service ||= begin
          service = Google::Apis::DriveV3::DriveService.new
          service.authorization = authorization
          service
        end
      end

      def upload_file(io:, filename:, mime_type:)
        file = drive_service.create_file(metadata(filename: filename), upload_source: io, supports_all_drives: true)
        drive_service.create_permission(file.id, permission)
        file.id
      rescue Google::Apis::ClientError => e
        raise GoogleDrive::Errors::UploadError, "Failed to upload file: #{e.message}"
      end

      def get_file(file_id)
        drive_service.get_file(file_id, fields: "id,name,mime_type,webContentLink,webViewLink,thumbnailLink", supports_all_drives: true)
      rescue Google::Apis::ClientError => e
        raise GoogleDrive::Errors::UploadError, "Failed to retrieve file: #{e.message}"
      end

      def delete_file(file_id)
        drive_service.delete_file(file_id)
      rescue Google::Apis::ClientError, Google::Apis::ServerError => e
        raise GoogleDrive::Errors::DeleteError, "Failed to delete file: #{e.message}"
      rescue Google::Apis::AuthorizationError => e
        raise GoogleDrive::Errors::AuthorizationError, "Authorization error: #{e.message}"
      end

      def metadata(filename:)
        Google::Apis::DriveV3::File.new(name: filename, parents: [ folder_id ])
      end

      def permission
        Google::Apis::DriveV3::Permission.new(type: PERMISSION_TYPE, role: PERMISSION_ROLE)
      end

      def authorization
        GoogleDrive::Auth.authorization
      end

      def folder_id
        Rails.application.credentials.dig(:google_drive, :folder_id)
      end
    end
  end
end
