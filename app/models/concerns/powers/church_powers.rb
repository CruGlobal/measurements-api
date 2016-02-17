module Powers
  module ChurchPowers
    extend ActiveSupport::Concern

    included do
      # Power definitions
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
