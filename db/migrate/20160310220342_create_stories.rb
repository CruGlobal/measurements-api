class CreateStories < ActiveRecord::Migration
  def change
    create_table :stories do |t|
      t.string :title
      t.text :content
      t.string :image
      t.string :mcc, limit: 3
      t.references :church, index: true
      t.references :training, index: true
      t.decimal :latitude
      t.decimal :longitude
      t.string :language
      t.boolean :privacy, default: false
      t.text :video_url
      t.integer :state

      t.timestamps null: false
    end

    add_foreign_key :stories, :churches, on_update: :cascade, on_delete: :nullify
    add_foreign_key :stories, :trainings, on_update: :cascade, on_delete: :nullify
  end
end
