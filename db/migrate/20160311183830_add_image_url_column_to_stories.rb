class AddImageUrlColumnToStories < ActiveRecord::Migration[4.2]
  def change
    add_column :stories, :image_url, :string
    change_column :stories, :video_url, :string
  end
end
