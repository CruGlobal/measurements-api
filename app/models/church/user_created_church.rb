class Church
  class UserCreatedChurch < ::Church
    after_create :write_audit

    def write_audit
      Audit.create(ministry_id: ministry_id, person_id: created_by_id, audit_type: :new_church,
                   message: "A new church created by #{created_by.full_name}: #{name}")
    end

    authorize_values_for :ministry
  end
end
