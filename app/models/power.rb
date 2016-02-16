class Power
  include Consul::Power

  def initialize(user, ministry_id)
    @user = user
    ministry_id = ministry_id.ministry_id if ministry_id.is_a?(Ministry)
    @assignment = user.assignment_for_ministry(ministry_id) if user
  end

  power :assignments do
    nil
  end

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
