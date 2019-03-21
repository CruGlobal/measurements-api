class CreateAudits < ActiveRecord::Migration[4.2]
  def change
    create_table :audits do |t|
      t.uuid :person_id, null: false
      t.uuid :ministry_id, null: false
      t.string :message, null: false
      t.integer :audit_type, null: false
      t.string :ministry_name
      t.datetime :created_at
    end
  end
end
