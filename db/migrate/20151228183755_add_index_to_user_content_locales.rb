class AddIndexToUserContentLocales < ActiveRecord::Migration[4.2]
  def change
    add_index :user_content_locales, %w(person_id ministry_id), unique: true
  end
end
