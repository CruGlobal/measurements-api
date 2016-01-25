class CreateMinistries < ActiveRecord::Migration
  def change
    create_table :ministries do |t|
      t.uuid :ministry_id
      t.string :name
      t.string :min_code
      t.float :lat
      t.float :long
      t.integer :zoom
      t.string :lmi_show, array: true
      t.string :lmi_hide, array: true
      t.boolean :slm
      t.boolean :llm
      t.boolean :gcm
      t.boolean :ds
      t.string :default_mcc
      t.uuid :parent_ministry_id

      t.timestamps null: false
    end
  end
end
