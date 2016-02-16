class Power
  include Consul::Power
  include Powers::AssignmentPowers
  include Powers::ChurchPowers

  def initialize(user, ministry_id)
    @user = user
    ministry_id = ministry_id.ministry_id if ministry_id.is_a?(Ministry)
    @assignment = user.assignment_for_ministry(ministry_id) if user
  end

  power :assignments do
    nil
  end
end
