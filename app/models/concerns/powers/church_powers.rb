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
  end
end
