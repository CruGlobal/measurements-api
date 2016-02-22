class CreateTrainingCompletions < ActiveRecord::Migration
  def change
    create_table :training_completions do |t|
      t.integer :phase
      t.integer :number_completed
      t.datetime :date
      t.references :training, index: true

      t.timestamps null: false
    end

    add_foreign_key :training_completions, :trainings, on_update: :cascade, on_delete: :restrict
  end
end
