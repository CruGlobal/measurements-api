class CreateTrainings < ActiveRecord::Migration
  def change
    create_table :trainings do |t|
      t.references :ministry, index: true
      t.string :name
      t.datetime :date
      t.string :type, limit: 50
      t.string :mcc, limit: 3
      t.decimal :latitude
      t.decimal :longitude
      t.references :created_by, index: true

      t.timestamps null: false
    end

    add_foreign_key :trainings, :ministries, on_update: :cascade, on_delete: :restrict
    add_foreign_key :trainings, :people, column: :created_by_id, on_update: :cascade, on_delete: :restrict
  end
end
