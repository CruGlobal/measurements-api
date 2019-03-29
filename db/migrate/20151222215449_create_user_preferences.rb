class CreateUserPreferences < ActiveRecord::Migration[4.2]
  def change
    create_table :user_preferences do |t|
      t.uuid :person_id
      t.string :name
      t.string :value

      t.timestamps null: false
    end
  end
end
