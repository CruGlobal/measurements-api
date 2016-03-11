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
      Assignment.create(ministry_id: id, person_id: created_by.id, role: :admin)
    end
  end
end
