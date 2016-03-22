# frozen_string_literal: true
module Powers
  module MeasurementPowers
    extend ActiveSupport::Concern

    included do
      # Power definitions
      power :historic_measurements do
        inherited_assignment.try(:leader_role?)
      end

      power :measurements do
        true
      end

      power :showing_measurement do
        true if inherited_assignment.try(:leader_role?)
      end
    end

    def measurement_levels
      levels = []
      levels << :total if inherited_assignment.try(:approved_role?)
      levels << :local if inherited_assignment.try(:leader_role?)
      levels << :person if assignment.present? && !assignment.blocked_role?
      levels
    end
  end
end
