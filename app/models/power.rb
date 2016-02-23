class Power
  include Consul::Power

  def initialize(user, ministry_id = nil)
    @user = user
    return if ministry_id.blank? || user.blank?
    @assignment = user.assignment_for_ministry(ministry_id)
  end

  include Powers::AssignmentPowers
  include Powers::ChurchPowers
  include Powers::TrainingPowers
  include Powers::MinistryPowers

  protected

  attr_reader :user, :assignment
end
