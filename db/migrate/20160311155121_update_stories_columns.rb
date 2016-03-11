class UpdateStoriesColumns < ActiveRecord::Migration
  def change
    change_column :stories, :state, :integer, default: 0
    remove_column :stories, :privacy
    add_column :stories, :privacy, :integer, default: 0
  end
end
