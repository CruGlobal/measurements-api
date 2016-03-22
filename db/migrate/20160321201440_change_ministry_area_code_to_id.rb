class ChangeMinistryAreaCodeToId < ActiveRecord::Migration
  def change
    remove_column :ministries, :area_code, :string
    add_column :ministries, :area_id, :integer
  end
end
