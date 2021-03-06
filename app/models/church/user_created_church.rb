# frozen_string_literal: true

class Church
  class UserCreatedChurch < ::Church
    before_save :default_values
    after_create :write_audit
    validates :name, presence: {message: "Could not find required field: 'name'"}
    validates :ministry, presence: {message: "Could not find required field: 'ministry_id'"}

    def write_audit
      Audit.create(ministry_id: ministry_id, person_id: created_by_id, audit_type: :new_church,
                   message: "A new church created by #{created_by.full_name}: #{name}")
    end

    def default_values
      self.start_date ||= Time.zone.today
    end

    authorize_values_for :ministry
  end
end
