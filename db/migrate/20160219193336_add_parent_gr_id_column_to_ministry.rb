class AddParentGrIdColumnToMinistry < ActiveRecord::Migration
  def change
    add_column :ministries, :parent_gr_id, :uuid
  end
end
