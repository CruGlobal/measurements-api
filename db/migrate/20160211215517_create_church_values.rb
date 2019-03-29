class CreateChurchValues < ActiveRecord::Migration[4.2]
  def change
    create_table :church_values do |t|
      t.integer :church_id
      t.integer :size
      t.integer :development
      t.string :period
    end
  end
end
