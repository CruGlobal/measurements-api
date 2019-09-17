# frozen_string_literal: true

module Powers
  module AssignmentPowers
    extend ActiveSupport::Concern

    included do
      # Power definitions
      power :assignments do
        # Users can only get their direct assignments
        user.assignments
      end

      power :showable_assignments do
        # POWER is current_user and ministry of assignment
        # Leaders of ministry can show assignments
        if inherited_assignment.try(:leader_role?)
          Assignment.where(ministry: inherited_assignment.ministry)
        elsif assignment.present?
          # Users can view their assignments
          direct_assignments
        end
      end

      # power :create_assignment do
      #   # POWER is current_user and ministry of new assignment
      #   # Anyone can create an assignment unless you already have a direct assignment
      #   true if assignment.blank?
      # end

      power :updateable_assignments do
        # POWER is current_user and ministry of updated assignment
        # You may not change your own assignment
        # Leaders may update assignments
        if inherited_assignment.try(:leader_role?)
          Assignment.where.not(person_id: user.id)
            .where(ministry_id: inherited_assignment.ministry_id)
        end
      end

      def direct_assignments
        Assignment.where(person: user)
      end
    end

    def assignable_assignment_roles(_updated_assignment)
      Assignment::VALID_INPUT_ROLES
    end

    def assignable_assignment_user_created_assignment_roles(new_assignment)
      # Creating an assignment for ourselves
      if new_assignment.person_id == user.id
        # Leaders can not create another assignment for themselves on sub-ministries
        return [] if inherited_assignment.try(:leader_role?)

        # Anyone can self-assign themselves
        ["self_assigned"]
      else
        # Leaders can create assignments for others
        return Assignment::VALID_INPUT_ROLES if inherited_assignment.try(:leader_role?)

        # Users may not create assignments for others
        []
      end
    end

    def role_approved?
      assignment.try(:approved_role?) || inherited_assignment.try(:approved_role?)
    end
  end
end
