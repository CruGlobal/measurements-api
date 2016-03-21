class CreateAreas < ActiveRecord::Migration
  def change
    create_table :areas do |t|
      t.uuid :gr_id
      t.string :code
      t.string :name
      t.boolean :active

      t.timestamps null: false
    end
  end
end
