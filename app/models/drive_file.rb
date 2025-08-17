class DriveFile < ApplicationRecord
  belongs_to :attachable, polymorphic: true

  validates :drive_file_id, presence: true
  validates :mime_type, presence: true

  after_destroy :remove_drive_file

  attr_accessor :file

  def preview_url
    return nil if drive_file_id.blank?

    "https://drive.google.com/thumbnail?id=#{drive_file_id}&sz=w1000"
  end

  def download_url
    return nil if drive_file_id.blank?

    "https://drive.google.com/uc?export=download&id=#{drive_file_id}"
  end

  def image_file?
    return false unless drive_mime_type.present?

    drive_mime_type.start_with?('image/')
  end

  def drive_file
    return nil if drive_file_id.blank?

    GoogleDrive::DriveService.get_file(drive_file_id)
  rescue GoogleDrive::Errors::UploadError => e
    Rails.logger.error("Failed to retrieve file: #{e.message}")
    nil
  end

  private

  def remove_drive_file
    GoogleDrive::DriveService.delete_file(drive_file_id)
  end
end
