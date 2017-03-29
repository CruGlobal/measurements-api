# frozen_string_literal: true
module Powers
  module ChurchPowers
    extend ActiveSupport::Concern

    included do
      # Power definitions

      power :changeable_churches do
        break nil if blocked?
        churches = Church.where(ministry: fallback_assignment.ministry)
        break churches unless assignment.try(:self_assigned?)
        churches.where('security >= ?', Church.securities[:registered_public_church])
      end

      power :churches do
        Church.all
      end
    end

    def assignable_church_securities
      if blocked?
        []
      elsif assignment.try(:self_assigned?)
        %w(registered_public_church global_public_church)
      else
        Church.securities.keys
      end
    end

    def assignable_church_ministries
      # this should only be called in the context of a user update
      return Ministry.all.pluck(:id) if user.blank?
      Ministry.includes(:assignments).where(assignments: { person: user })
              .where(assignments: Assignment.leader_condition)
    end

    def assignable_church_user_created_church_ministries
      # inherited_assignment.ministry_id is going to be the id the user is trying to create a church on
      [fallback_assignment.ministry] unless blocked?
    end

    def visiable_local_churches_security
      if blocked?
        Church.securities['registered_public_church']
      elsif assignment.blank? || assignment.self_assigned?
        Church.securities['private_church']
      else
        Church.securities['local_private_church']
      end
    end

    def fallback_assignment
      @fallback_assignment ||= inherited_assignment || assignment
    end

    def blocked?
      assignment.try(:blocked_role?) || fallback_assignment.blank?
    end
  end
end
