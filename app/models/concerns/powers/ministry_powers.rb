# frozen_string_literal: true
module Powers
  module MinistryPowers
    extend ActiveSupport::Concern

    included do
      power :ministries do
        # Anyone can view all ministries, serializer restricts attributes to name and ministry_id
        Ministry.all
      end

      power :show_ministry do
        # Only leaders/inherited leaders may show or update a ministry
        ministry if inherited_assignment.present?
      end

      power :update_ministry do
        # Only leaders/inherited leaders may show or update a ministry
        next unless ministry.present? && inherited_assignment.present?
        ::Ministry::UserUpdatedMinistry.new(ministry)
      end

      power :create_ministry do
        # current Assignment is for parent ministry
        # Anyone can create Ministries, only leaders of a ministry can create sub-ministries
        ::Ministry::UserCreatedMinistry unless ministry.present? && inherited_assignment.blank?
      end
    end

    def assignable_ministry_parent_ids
      # All Inherited ministries (admin/leader ancestors)
      ids = Ministry.inherited_ministries(user).pluck(:id)
      # Direct Leaders of this ministry may orphan the ministry
      ids << nil if assignment.present? && assignment.leader_role?(false)
      ids
    end

    def assignable_ministry_user_created_ministry_parent_ids
      # Called during user creation of a new Ministry, assignment here is for the parent ministry if set
      # All Inherited ministries (admin/leader ancestors)
      ids = Ministry.inherited_ministries(user).pluck(:id)
      # Anyone can create a ministry without a parent
      ids << nil
      ids
    end
  end
end
