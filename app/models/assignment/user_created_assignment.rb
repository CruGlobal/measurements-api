class Assignment
  class UserCreatedAssignment < ::Assignment
    # Virtual attributes
    attr_accessor :username, :key_guid, :person_gr_id, :ministry_gr_id

    before_validation :lookup_person, on: :create
    before_validation :lookup_ministry, on: :create

    # validates :role, inclusion: { in: VALID_INPUT_ROLES,
    #                               message: '\'%{value}\' is not a valid Team Role' }

    authorize_values_for :role

    protected

    def lookup_ministry
      return if ministry_gr_id.blank?
      self.ministry = Ministry.ministry(ministry_gr_id)
    end

    def lookup_person
      if person_gr_id.present?
        self.person = Person.find_by(gr_id: person_gr_id)
      elsif !username.blank?
        self.person = Person.person_for_username(username)
      elsif !key_guid.blank?
        # Legacy GMA identities saved user login as guid
        self.person = if key_guid.include?('@')
                        Person.person_for_username(key_guid)
                      else
                        Person.person(key_guid)
                      end
      end
    end
  end
end
