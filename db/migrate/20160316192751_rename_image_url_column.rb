class RenameImageUrlColumn < ActiveRecord::Migration[4.2]
  def change
    rename_column :stories, :image_url, :user_image_url
  end
end
