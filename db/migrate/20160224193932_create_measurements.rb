class CreateMeasurements < ActiveRecord::Migration[4.2]
  def change
    create_table :measurements do |t|
      t.string :perm_link
      t.string :english
      t.string :description
      t.string :section
      t.string :column
      t.integer :sort_order
      t.uuid :total_id
      t.uuid :local_id
      t.uuid :person_id
      t.boolean :stage
      t.integer :parent_id
      t.boolean :leader_only
      t.boolean :supported_staff_only
      t.string :mcc_filter

      t.timestamps null: false
    end
  end
end
