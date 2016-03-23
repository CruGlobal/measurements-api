# frozen_string_literal: true
class Assignment
  class UserCreatedAssignment < ::Assignment
    # Virtual attributes
    attr_accessor :username,
                  :key_guid,
                  :person_gr_id,
                  :ministry_gr_id,
                  :first_name,
                  :last_name,
                  :email,
                  :preferred_name,
                  :ea_guid

    before_validation :lookup_person, on: :create
    before_validation :lookup_ministry, on: :create

    before_create :create_gr_relationship

    authorize_values_for :role

    private

    def lookup_ministry
      return if ministry_gr_id.blank?
      self.ministry = Ministry.ministry(ministry_gr_id)
    end

    def lookup_person
      if person_gr_id.present?
        self.person = Person.for_gr_id(person_gr_id)
      elsif !username.blank?
        self.person = find_or_create_person_by_username(username)
      elsif !key_guid.blank?
        # Legacy GMA identities saved user login as guid
        self.person = if key_guid.include?('@')
                        find_or_create_person_by_username(key_guid)
                      else
                        Person.person(key_guid)
                      end
      end
      create_person if person.blank?
    end

    def find_or_create_person_by_username(username)
      Person.person_for_username(username) || create_person_from_username(username)
    end

    def create_person_from_username(username)
      Person.create!(cas_username: username)
    end
  end
end
