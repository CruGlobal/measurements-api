class AddEaGuidToPeople < ActiveRecord::Migration
  def change
    add_column :people, :ea_guid, :uuid
  end
end
