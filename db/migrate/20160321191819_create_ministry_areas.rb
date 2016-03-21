class CreateMinistryAreas < ActiveRecord::Migration
  def change
    create_table :ministry_areas do |t|
      t.integer :ministry_id, null: false
      t.integer :area_id, null: false
      t.uuid :gr_id
      t.integer :created_by_id
      t.boolean :user_entered

      t.timestamps null: false
    end
  end
end
