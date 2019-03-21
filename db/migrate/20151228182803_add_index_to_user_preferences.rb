class AddIndexToUserPreferences < ActiveRecord::Migration[4.2]
  def change
    add_index :user_preferences, %w(person_id name), unique: true
  end
end
