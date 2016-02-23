class Ministry
  class UserCreatedMinistry < ::Ministry
    # Virtual Attribute
    attr_accessor :created_by

    validates :min_code, presence: true, uniqueness: true, on: :create
    before_validation :generate_min_code, on: :create, if: 'gr_id.blank?'

    authorize_values_for :parent_id

    after_create :create_admin_assignment

    private

    def create_admin_assignment
      return unless created_by.present?
      Assignment.create(ministry_id: id, person_id: created_by.id, role: :admin)
    end

    # Prefix new ministries min_code with parent min_code if WHQ ministry
    def generate_min_code
      return unless min_code.is_a? String
      self.min_code = min_code.downcase.gsub(/\s+/, '_')
      ministry = parent_whq_ministry(parent)
      self.min_code = [ministry.min_code, min_code].join('_') unless ministry.nil?
    end
  end
end
