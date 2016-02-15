class FixSomeChruchesFields < ActiveRecord::Migration
  def change
    remove_column :churches, :target_area
    add_column :churches, :vc_id, :integer
  end
end
