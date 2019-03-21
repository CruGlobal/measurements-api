class CreateUserContentLocales < ActiveRecord::Migration[4.2]
  def change
    create_table :user_content_locales do |t|
      t.uuid :person_id
      t.uuid :ministry_id
      t.string :locale

      t.timestamps null: false
    end
  end
end
