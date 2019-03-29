class AddParentGrIdColumnToMinistry < ActiveRecord::Migration[4.2]
  def change
    add_column :ministries, :parent_gr_id, :uuid
  end
end
