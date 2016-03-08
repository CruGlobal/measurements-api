module Powers
  module MeasurementPowers
    extend ActiveSupport::Concern

    included do
      # Power definitions
    end

    def measurement_levels
      levels = []
      levels << :total if assignment.try(:approved_role?) || inherited_assignment.try(:approved_role?)
      levels << :local if assignment.try(:leader_role?) || inherited_assignment.try(:leader_role?)
      levels << :person if assignment.present? && !assignment.blocked_role?
      levels
    end
  end
end
