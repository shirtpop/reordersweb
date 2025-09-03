module GoogleDrive
  module Errors
    class Error < StandardError; end
    class AuthorizationError < Error; end
    class UploadError < Error; end
    class DeleteError < Error; end
  end
end
