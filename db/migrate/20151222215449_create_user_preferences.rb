class CreateUserPreferences < ActiveRecord::Migration
  def change
    create_table :user_preferences do |t|
      t.uuid :person_id
      t.string :name
      t.string :value

      t.timestamps null: false
    end
  end
end
