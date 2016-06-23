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

    before_validation :assign_ministry, on: :create
    before_validation :assign_person, on: :create

    before_create :create_gr_relationship

    authorize_values_for :role

    private

    def assign_ministry
      return if ministry_gr_id.blank?
      self.ministry = Ministry.ministry(ministry_gr_id)
    end

    def assign_person
      self.person = Person.person_for_gr_id(person_gr_id) ||
                    person_for_key_guid || Person.person_for_ea_guid(ea_guid) ||
                    person_by_username
    end

    def person_for_key_guid
      return if key_guid.blank?
      # Legacy GMA identities saved user login as guid
      if key_guid.include?('@')
        self.email = key_guid.strip
        self.key_guid = nil
        person_by_email
      else
        Person.person(key_guid)
      end
    end

    def person_by_username
      return if username.blank?
      Person.person_for_username(username) || create_person_from_params
    end

    def person_by_email
      return if email.blank?
      Person.person_for_email(email) || create_person_from_params
    end

    def create_person_from_params
      person = Person.create(
        cas_username: username, first_name: first_name, last_name: last_name,
        email: email, preferred_name: preferred_name)
      person.create_entity
      person.save!
      person
    end
  end
end
