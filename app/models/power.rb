# frozen_string_literal: true

class Power
  include Consul::Power

  def initialize(user, ministry = nil)
    # Power requires a valid user, ministry optional
    raise(Consul::Error, "User required") unless user.present?
    @user = user
    @ministry = if ministry.is_a? Integer
      Ministry.find_by(id: ministry)
    elsif Uuid.uuid? ministry
      Ministry.ministry(ministry)
    elsif ministry.is_a? Ministry
      ministry
    end
  end

  include Powers::AssignmentPowers
  include Powers::ChurchPowers
  include Powers::TrainingPowers
  include Powers::MinistryPowers
  include Powers::MeasurementPowers
  include Powers::StoryPowers
  include Powers::AuditPowers

  attr_reader :user, :ministry

  # Direct Assignment at this ministry
  def assignment
    return @assignment if @assignment_set
    @assignment = user.assignment_for_ministry(ministry) unless ministry.blank?
    @assignment_set = true
    @assignment
  end

  # Inherited admin or leader Assignment at this ministry
  def inherited_assignment
    return @inherited_assignment if @inherited_assignment_set
    @inherited_assignment = user.inherited_assignment_for_ministry(ministry) unless ministry.blank?
    @inherited_assignment_set = true
    @inherited_assignment
  end
end
