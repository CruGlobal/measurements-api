module Powers
  module MeasurementPowers
    extend ActiveSupport::Concern

    included do
      # Power definitions
    end

    def measurement_levels
      return [:person] if assignment && assignment.self_assigned?
      [:total, :local, :person]
    end
  end
end
