class RenameChurchCreatedByToCreatedById < ActiveRecord::Migration
  def change
    rename_column :churches, :created_by, :created_by_id
  end
end
