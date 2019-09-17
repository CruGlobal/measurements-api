class UpdateForeignKeys < ActiveRecord::Migration[4.2]
  def change
    # Run rake db:reset before this migration
    # Change foreign key columns to integers (can't cast uuid to integer, so set value to null)
    change_column :user_preferences, :person_id, "integer USING null"
    change_column :user_measurement_states, :person_id, "integer USING null"
    change_column :user_map_views, :person_id, "integer USING null"
    change_column :user_map_views, :ministry_id, "integer USING null"
    change_column :user_content_locales, :person_id, "integer USING null"
    change_column :user_content_locales, :ministry_id, "integer USING null"
    change_column :ministries, :parent_id, "integer USING null"
    rename_column :churches, :target_area_id, :ministry_id
    change_column :churches, :ministry_id, "integer USING null"
    rename_column :churches, :created_by_id, :person_id
    change_column :churches, :person_id, "integer USING null"
    change_column :audits, :person_id, "integer USING null"
    change_column :audits, :ministry_id, "integer USING null"
    change_column :assignments, :person_id, "integer USING null"
    change_column :assignments, :ministry_id, "integer USING null"

    # Rename Global Registry id columns
    rename_column :people, :person_id, :gr_id
    rename_column :ministries, :ministry_id, :gr_id
    rename_column :churches, :church_id, :gr_id
    rename_column :assignments, :assignment_id, :gr_id

    # Add Foreign Key constraints
    add_foreign_key :user_preferences, :people, on_delete: :cascade, on_update: :cascade
    add_foreign_key :user_measurement_states, :people, on_delete: :cascade, on_update: :cascade
    add_foreign_key :user_map_views, :people, on_delete: :cascade, on_update: :cascade
    add_foreign_key :user_map_views, :ministries, on_delete: :cascade, on_update: :cascade
    add_foreign_key :user_content_locales, :people, on_delete: :cascade, on_update: :cascade
    add_foreign_key :user_content_locales, :ministries, on_delete: :cascade, on_update: :cascade
    add_foreign_key :ministries, :ministries, column: :parent_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :churches, :people, on_delete: :restrict, on_update: :cascade
    add_foreign_key :churches, :ministries, on_delete: :restrict, on_update: :cascade
    add_foreign_key :churches, :churches, column: :parent_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :church_values, :churches, on_delete: :restrict, on_update: :cascade
    add_foreign_key :audits, :people, on_delete: :cascade, on_update: :cascade
    add_foreign_key :audits, :ministries, on_delete: :cascade, on_update: :cascade
    add_foreign_key :assignments, :people, on_delete: :cascade, on_update: :cascade
    add_foreign_key :assignments, :ministries, on_delete: :cascade, on_update: :cascade

    # Add missing unique indexes
    add_index :assignments, [:person_id, :ministry_id], unique: true
    add_index :churches, :gr_id, unique: true
    add_index :church_values, [:church_id, :period], unique: true
  end
end
