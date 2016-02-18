class Ministry
  class UserCreatedMinistry < ::Ministry
    validates :min_code, uniqueness: true, on: :create
    before_validation :generate_min_code, on: :create, if: 'ministry_id.blank?'

    # Prefix new ministries min_code with parent min_code if WHQ ministry
    def generate_min_code
      self.min_code = min_code.downcase.gsub(/\s+/, '_')
      ministry = parent_whq_ministry(parent)
      self.min_code = [ministry.min_code, min_code].join('_') unless ministry.nil?
    end
  end
end
