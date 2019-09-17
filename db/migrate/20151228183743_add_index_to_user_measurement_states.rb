class AddIndexToUserMeasurementStates < ActiveRecord::Migration[4.2]
  def change
    add_index :user_measurement_states, %w[person_id mcc perm_link_stub],
              unique: true, name: "unique_index_user_measurement_states"
  end
end
