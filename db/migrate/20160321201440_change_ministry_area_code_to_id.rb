class ChangeMinistryAreaCodeToId < ActiveRecord::Migration[4.2]
  def change
    remove_column :ministries, :area_code, :string
    add_column :ministries, :area_id, :integer
  end
end
