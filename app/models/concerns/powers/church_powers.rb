module Powers
  module ChurchPowers
    extend ActiveSupport::Concern

    included do
      # Power definitions

      power :changeable_churches do
        break nil if @assignment.blank? || @assignment.blocked_role?
        churches = Church.where(target_area_id: @assignment.ministry_id)
        churches = churches.where('security >= ?', Church.securities[:public_church]) if @assignment.self_assigned?
        churches
      end

      power :churches do
        Church.all
      end
    end

    def assignable_church_securities
      if @assignment.blank? || @assignment.blocked_role?
        []
      elsif @assignment.self_assigned?
        ['public_church']
      else
        Church.securities.keys
      end
    end

    def assignable_church_target_area_ids
      # this should only be called in the context of a user update
      return Ministry.all.pluck(:ministry_id) if @user.blank?
      Assignment.where(person: @user).leaders.pluck(:ministry_id)
    end

    def assignable_church_target_area_ids_on_create
      # assigment.ministry_id is going to be the id the user is trying to create a church on
      [@assignment.ministry_id] if @assignment.present? && !@assignment.blocked?
    end

    def visiable_local_churches_security
      if @assignment.blank? || @assignment.blocked_role?
        Church.securities['public_church']
      elsif @assignment.inherited_role?
        Church.securities['private_church']
      else
        Church.securities['local_private_church']
      end
    end
  end
end
