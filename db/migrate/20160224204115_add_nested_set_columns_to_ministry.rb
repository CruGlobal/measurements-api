class AddNestedSetColumnsToMinistry < ActiveRecord::Migration[4.2]
  def change
    remove_column :ministries, :parent_id
    add_column :ministries, :parent_id, :integer, null: true, index: true
    add_column :ministries, :lft, :integer, null: false, index: true
    add_column :ministries, :rgt, :integer, null: false, index: true
    add_column :ministries, :depth, :integer, null: false, default: 0
  end
end
