class AddImageUrlColumnToStories < ActiveRecord::Migration
  def change
    add_column :stories, :image_url, :string
    change_column :stories, :video_url, :string
  end
end
