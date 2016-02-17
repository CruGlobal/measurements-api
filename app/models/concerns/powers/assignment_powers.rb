module Powers
  module AssignmentPowers
    extend ActiveSupport::Concern

    included do
      # Power definitions
      power :role_approved do
        @assignment.present? && @assignment.approved_role?
      end
    end
  end
end
