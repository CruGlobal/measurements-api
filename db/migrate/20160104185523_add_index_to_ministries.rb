class AddIndexToMinistries < ActiveRecord::Migration
  def change
    add_index :ministries, :ministry_id, unique: true
  end
end
