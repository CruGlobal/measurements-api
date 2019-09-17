# frozen_string_literal: true

class MeasurementType
  class UserCreatedMeasurementType < ::MeasurementType
    validates :english, presence: {message: "Could not find required field: 'english'"}
    validates :perm_link_stub, presence: {message: "Could not find required field: 'perm_link_stub'"}
    validate :check_perm_link_start, :check_perm_link_unique

    def check_perm_link_start
      %w[local_ total_ custom_].each do |start|
        if perm_link_stub.downcase.start_with?(start)
          errors.add(:perm_link_stub, " is invalid. It cannot start with: '#{start}'")
        end
      end
    end

    def check_perm_link_unique
      matching_measurement = Measurement.find_by_perm_link(perm_link_stub)
      return unless matching_measurement && matching_measurement.id != measurement.id

      errors.add(:perm_link_stub, "perm_link_stub is being used by another measurement_type. It must be unique.")
    end
  end
end
