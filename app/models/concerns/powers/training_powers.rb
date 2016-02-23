module Powers
  module TrainingPowers
    extend ActiveSupport::Concern

    included do
      # Power definitions
      power :trainings do
        Training.where(ministry: @assignment.ministry) if @assignment.leader_role?
      end
    end

    def assignable_training_ministries
      # this should only be called in the context of a user update
      return Ministry.all.pluck(:id) if @user.blank?
      Ministry.includes(:assignments).where(assignments: { person: @user })
              .where(assignments: Assignment.leader_condition)
    end

    def assignable_training_ministries_on_create
      # assigment.ministry_id is going to be the id the user is trying to create a training on
      [@assignment.ministry] if @assignment.present? && !@assignment.blocked?
    end
  end
end
