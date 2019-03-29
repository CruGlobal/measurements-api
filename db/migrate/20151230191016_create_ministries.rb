class CreateMinistries < ActiveRecord::Migration[4.2]
  def change
    create_table :ministries do |t|
      t.uuid :ministry_id
      t.uuid :parent_id
      t.string :name
      t.string :min_code
      t.string :area_code
      t.string :mccs, array: true, default: []
      t.string :default_mcc
      t.float :latitude
      t.float :longitude
      t.integer :location_zoom
      t.string :lmi_show, array: true, default: []
      t.string :lmi_hide, array: true, default: []
      t.boolean :hide_reports_tab
      t.string :currency_code
      t.string :currency_symbol
      t.string :ministry_scope

      t.timestamps null: false
    end

    add_index :ministries, [:ministry_id], name: 'index_ministries_on_ministry_id', unique: true, using: :btree
    add_index :ministries, [:min_code], name: 'index_ministries_on_min_code', unique: true, using: :btree
  end
end
