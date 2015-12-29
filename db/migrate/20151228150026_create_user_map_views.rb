class CreateUserMapViews < ActiveRecord::Migration
  def change
    create_table :user_map_views do |t|
      t.uuid :person_id
      t.uuid :min_id
      t.float :lat
      t.float :long
      t.integer :zoom

      t.timestamps null: false
    end
  end
end
