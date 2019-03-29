class AddPersonAndMinistryToStory < ActiveRecord::Migration[4.2]
  def change
    add_reference :stories, :created_by, index: true
    add_reference :stories, :ministry, index: true

    add_foreign_key :stories, :people, column: :created_by_id, on_update: :cascade, on_delete: :nullify
    add_foreign_key :stories, :ministries, on_update: :cascade, on_delete: :cascade
  end
end
