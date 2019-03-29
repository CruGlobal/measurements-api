class UpdateEaGuidToString < ActiveRecord::Migration[4.2]
  def change
    change_column :people, :ea_guid, :string
  end
end
