class RenameChurchPersonIdToCreateById < ActiveRecord::Migration[4.2]
  def change
    remove_foreign_key :churches, :people
    rename_column :churches, :person_id, :created_by_id
    add_foreign_key :churches, :people, column: :created_by_id, on_delete: :restrict, on_update: :cascade
  end
end
