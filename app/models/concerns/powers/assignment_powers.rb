module Powers
  module AssignmentPowers
    extend ActiveSupport::Concern

    included do
      # Power definitions
    end

    def role_approved?
      @assignment.present? && @assignment.approved_role?
    end
  end
end
