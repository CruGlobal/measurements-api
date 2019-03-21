class CreateAssignments < ActiveRecord::Migration[4.2]
  def change
    create_table :assignments do |t|
      t.uuid :assignment_id
      t.uuid :person_id, null: false
      t.uuid :ministry_id, null: false
      t.integer :role, default: 2

      t.timestamps null: false
    end
  end
end
