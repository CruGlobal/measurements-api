class CreateChurches < ActiveRecord::Migration
  def change
    create_table :churches do |t|
      t.string :chruch_id
      t.string :name
      t.float :long
      t.float :lat
      t.datetime :start_date
      t.datetime :end_date
      t.boolean :jf_contrib
      t.references :parent, index: true
      t.integer :target_area
      t.string :target_area_id, limit: 36
      t.string :contact_name
      t.string :contact_email
      t.string :contact_mobile
      t.integer :generation
      t.integer :development
      t.integer :size
      t.integer :security
      t.string :created_by, limit: 36

      t.timestamps null: false
    end
  end
end
