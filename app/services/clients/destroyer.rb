module Clients
  class Destroyer
    class DeleteError < StandardError; end

    def initialize(client:)
      @client = client
    end

    def call!
      ActiveRecord::Base.transaction do
        @client.destroy!
      end
    rescue ActiveRecord::RecordNotFound, GoogleDrive::Errors::DeleteError => e
      raise DeleteError, "Failed to delete client or associated drive files: #{e.message}"
    end
  end
end
