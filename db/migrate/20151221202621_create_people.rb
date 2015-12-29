class CreatePeople < ActiveRecord::Migration
  def change
    create_table :people do |t|
      t.uuid :person_id
      t.string :first_name
      t.string :last_name
      t.uuid :cas_guid
      t.string :cas_username

      t.timestamps null: false
    end
  end
end
