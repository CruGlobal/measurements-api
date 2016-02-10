class Assignment::NewUserAssignment < ::Assignment # rubocop:disable Style/ClassAndModuleChildren
  # Virtual attributes
  attr_accessor :username, :key_guid

  before_validation :lookup_person, on: :create
  before_validation :lookup_ministry, on: :create

  protected

  def lookup_ministry
    return if ministry_id.blank?
    self.ministry = Ministry.ministry(ministry_id)
  end

  def lookup_person
    if !username.blank?
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
