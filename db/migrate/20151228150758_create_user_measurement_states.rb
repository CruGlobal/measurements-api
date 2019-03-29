class CreateUserMeasurementStates < ActiveRecord::Migration[4.2]
  def change
    create_table :user_measurement_states do |t|
      t.uuid :person_id
      t.string :mcc
      t.string :perm_link_stub
      t.boolean :visible

      t.timestamps null: false
    end
  end
end
