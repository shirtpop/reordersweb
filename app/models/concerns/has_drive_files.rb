module HasDriveFiles
  extend ActiveSupport::Concern

  included do
    has_many :drive_files, as: :attachable, dependent: :destroy

    validate :validate_drive_files_association

    after_destroy :remove_drive_files

    accepts_nested_attributes_for :drive_files, allow_destroy: true, reject_if: :all_blank
  end

  private

  def validate_drive_files_association
    drive_files.each do |drive_file|
      next if drive_file.marked_for_destruction?
      
      if drive_file.drive_file_id.blank?
        errors.add(:drive_files, "File upload failed for #{drive_file.filename}")
      end
    end
  end

  def remove_drive_files
    return if drive_files.empty?

    drive_files.each do |drive_file|
      GoogleDrive::DriveService.delete_file(drive_file.drive_file_id)
    end
  end
end