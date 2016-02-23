class Training
  class UserCreatedTraining < ::Training
    after_save :write_audit
    after_save :create_first_completion

    attr_accessor :participants

    def write_audit
      Audit.create(ministry_id: ministry_id, person_id: created_by_id, audit_type: :new_training,
                   message: "A new training created by #{created_by.full_name}: #{name}")
    end

    def create_first_completion
      return if participants.blank?
      completions.create(phase: 1, number_completed: participants, date: date)
    end

    assignable_values_for :ministry do
      Power.current.assignable_training_ministries_on_create
    end
  end
end
