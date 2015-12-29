class AddIndexToUserContentLocales < ActiveRecord::Migration
  def change
    add_index :user_content_locales, %w(person_id ministry_id), unique: true
  end
end
