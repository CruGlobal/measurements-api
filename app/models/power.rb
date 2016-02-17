class Power
  include Consul::Power

  def initialize(user, ministry_id = nil)
    @user = user
    return if ministry_id.blank?
    ministry = ministry_id.is_a?(Ministry) ? ministry_id : Ministry.ministry(ministry_id)
    @assignment = user.assignment_for_ministry(ministry.ministry_id) if user && ministry
  end

  include Powers::AssignmentPowers
  include Powers::ChurchPowers
  include Powers::MinistryPowers
end
