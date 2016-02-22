class Training
  class UserCreatedTraining < ::Training
    after_save :write_audit

    def write_audit
      Audit.create(ministry_id: ministry_id, person_id: created_by_id, audit_type: :new_training,
                   message: "A new training created by #{created_by.full_name}: #{name}")
    end
  end
end
