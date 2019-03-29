class AddIndexToUserMapViews < ActiveRecord::Migration[4.2]
  def change
    rename_column :user_map_views, :min_id, :ministry_id
    add_index :user_map_views, %w(person_id ministry_id), unique: true
  end
end
