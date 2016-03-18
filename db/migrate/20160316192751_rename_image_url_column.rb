class RenameImageUrlColumn < ActiveRecord::Migration
  def change
    rename_column :stories, :image_url, :user_image_url
  end
end
