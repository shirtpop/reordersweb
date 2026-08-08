class RenameRecipientEmailToPurposeOnClientCheckouts < ActiveRecord::Migration[8.0]
  def change
    rename_column :client_checkouts, :recipient_email, :purpose
  end
end
