class AddFieldsToPeople < ActiveRecord::Migration[4.2]
  def change
    add_column :people, :ea_guid, :uuid
    add_column :people, :email, :string
    add_column :people, :preferred_name, :string
  end
end
