# frozen_string_literal: true

class Ministry
  class UserCreatedMinistry < ::Ministry
    # Virtual Attribute
    attr_accessor :created_by

    authorize_values_for :parent_id

    validates :min_code, presence: true, on: :create

    after_create :create_admin_assignment

    private

    def create_admin_assignment
      return unless created_by.present?
      assignment = Assignment.new(ministry_id: id, person_id: created_by.id, role: "admin")
      assignment.create_gr_relationship
      assignment.save!
    end
  end
end
