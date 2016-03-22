# frozen_string_literal: true
module Powers
  module TrainingPowers
    extend ActiveSupport::Concern

    included do
      # Power definitions
      power :trainings do
        Training.where(ministry: inherited_assignment.ministry) if inherited_assignment.try(:leader_role?)
      end

      power :training_completions do
        return unless assignment.leader_role?
        TrainingCompletion.includes(:training).where(trainings: { ministry_id: assignment.ministry.id })
      end
    end

    def assignable_training_ministries
      # this should only be called in the context of a user update
      Ministry.includes(:assignments).where(assignments: { person: user })
              .where(assignments: Assignment.leader_condition)
    end

    def assignable_training_user_created_training_ministries
      # assignment.ministry_id is going to be the id the user is trying to create a training on
      [assignment.ministry] if assignment.present? && !assignment.blocked?
    end
  end
end
