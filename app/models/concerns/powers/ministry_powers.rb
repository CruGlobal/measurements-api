module Powers
  module MinistryPowers
    extend ActiveSupport::Concern

    included do
      power :ministries do
        # Anyone can view all ministries, serializer restricts attributes to name and ministry_id
        Ministry.all
      end

      power :show_ministry do
        # Only leaders may show or update a ministry
        assignment.ministry if assignment.present? && assignment.leader_role?
      end

      power :create_ministry do
        # current Power is for parent ministry
        # Anyone can create Ministries, only leaders of a ministry can create sub-ministries
        ::Ministry::UserCreatedMinistry unless assignment.present? && !assignment.leader_role?
      end
    end

    def assignable_ministry_parent_ids
      # All Ministries of which user has a leader role
      ids = Ministry.includes(:assignments).where(assignments: { person: user })
                    .where(assignments: Assignment.leader_condition).pluck(:id)
      # Direct Leaders of this ministry may remove the parent
      ids << nil if assignment.present? && assignment.leader_role?(false)
      ids
    end

    def assignable_ministry_user_created_ministry_parent_ids
      # All Ministries of which user has a leader role
      ids = assignable_ministry_parent_ids
      # Anyone can create a ministry without a parent
      ids << nil if assignment.blank?
      ids
    end
  end
end
