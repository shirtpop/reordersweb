class CreateDriveFiles < ActiveRecord::Migration[8.0]
  def change
    create_table :drive_files do |t|
      t.references :attachable, polymorphic: true
      t.string :drive_file_id
      t.string :mime_type
      t.string :filename

      t.timestamps
    end
  end
end
