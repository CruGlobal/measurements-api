class AddUniqueIndexes < ActiveRecord::Migration[4.2]
  def change
    add_index :people, :gr_id, unique: true
    add_index :people, :cas_guid, unique: true
  end
end
