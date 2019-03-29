class CreateMeasurementsTranslations < ActiveRecord::Migration[4.2]
  def change
    create_table :measurement_translations do |t|
      t.references :measurement, index: true
      t.string :language
      t.string :name
      t.string :description
      t.references :ministry, index: true

      t.timestamps null: false
    end

    add_foreign_key :measurement_translations, :ministries, on_update: :cascade, on_delete: :cascade
    add_foreign_key :measurement_translations, :measurements, on_update: :cascade, on_delete: :cascade
  end
end
