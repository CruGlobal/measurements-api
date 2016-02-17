class Power
  include Consul::Power

  def initialize(user, ministry_id = nil)
    @user = user
    ministry_id = ministry_id.ministry_id if ministry_id.is_a?(Ministry)
    @assignment = user.assignment_for_ministry(ministry_id) if user
  end

  include Powers::AssignmentPowers
  include Powers::ChurchPowers
  include Powers::MinistryPowers
end
