class ChangeChurchFields < ActiveRecord::Migration
  def change
    remove_column :churches, :church_id
    add_column :churches, :church_id, :uuid
    remove_column :churches, :target_area_id
    add_column :churches, :target_area_id, :uuid
    remove_column :churches, :created_by
    add_column :churches, :created_by, :uuid

    rename_column :churches, :lat, :latitude
    rename_column :churches, :long, :longitude
  end
end
