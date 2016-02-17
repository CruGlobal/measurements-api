module Powers
  module AssignmentPowers
    extend ActiveSupport::Concern

    included do
      # Power definitions
      power :role_approved do
        @assignment.present? && @assignment.approved?
      end
    end
  end
end
