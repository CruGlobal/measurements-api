class AddIndexToUserPreferences < ActiveRecord::Migration
  def change
    add_index :user_preferences, %w(person_id name), unique: true
  end
end
