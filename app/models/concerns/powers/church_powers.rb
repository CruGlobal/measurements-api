module Powers
  module ChurchPowers
    extend ActiveSupport::Concern

    def assignable_church_securities
      if @assignment.blank? || @assignment.blocked? || @assignment.former_member?
        []
      elsif @assignment.self_assigned?
        ['public_church']
      else
        Church.securities.keys
      end
    end

    def visiable_local_churches_security
      if @assignment.blank? || @assignment.blocked? || @assignment.former_member?
        Church.securities['public_church']
      elsif @assignment.role.start_with?('inherited_')
        Church.securities['private_church']
      else
        Church.securities['local_private_church']
      end
    end
  end
end
