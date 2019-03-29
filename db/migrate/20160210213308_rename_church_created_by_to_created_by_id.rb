class RenameChurchCreatedByToCreatedById < ActiveRecord::Migration[4.2]
  def change
    rename_column :churches, :created_by, :created_by_id
  end
end
