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
    rescue ActiveRecord::RecordNotFound, ActiveRecord::InvalidForeignKey, GoogleDrive::Errors::DeleteError => e
      raise DeleteError, "Failed to delete client or associated records: #{e.message}"
    rescue ActiveRecord::RecordNotDestroyed
      raise DeleteError, @client.errors.full_messages.to_sentence.presence || "Failed to delete client."
    end
  end
end
