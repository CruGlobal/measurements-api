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
        @assignment.ministry if @assignment.present? && @assignment.leader_role?
      end

      power :create_ministry do
        # current_power is for new parent ministry
        # Anyone can create Ministries, only leaders of a ministry can create sub-ministries
        ::Ministry::UserCreatedMinistry unless @assignment.present? && !@assignment.leader_role?
      end
    end

    def assignable_ministry_parents
      Ministry.includes(:assignments)
              .where(assignments: { person: @user })
              .where(assignments: Assignment.leader_condition)
    end
  end
end
