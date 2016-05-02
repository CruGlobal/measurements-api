class UpdateEaGuidToString < ActiveRecord::Migration
  def change
    change_column :people, :ea_guid, :string
  end
end
