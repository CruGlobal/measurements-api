class CreateAssignments < ActiveRecord::Migration
  def change
    create_table :assignments do |t|
      t.uuid :assignment_id
      t.uuid :person_id
      t.uuid :ministry_id
      t.integer :role, default: 2

      t.timestamps null: false
    end
  end
end
