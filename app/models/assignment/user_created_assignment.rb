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
                  :preferred_name,
                  :ea_guid

    before_validation :assign_person, on: :create
    before_validation :assign_ministry, on: :create

    before_create :create_gr_relationship

    authorize_values_for :role

    private

    def assign_ministry
      return if ministry_gr_id.blank?
      self.ministry = Ministry.ministry(ministry_gr_id)
    end

    def assign_person
      self.person = Person.person_for_gr_id(person_gr_id) ||
                    person_by_username || person_for_key_guid
    end

    def person_for_key_guid
      # Legacy GMA identities saved user login as guid
      if key_guid.include?('@')
        person_by_username(key_guid)
      else
        Person.person(key_guid)
      end
    end

    def person_by_username
      return if username.blank?
      Person.person_for_username(username) || create_person_from_params
    end

    def create_person_from_params
      person = Person.new(
        cas_username: username, first_name: first_name, last_name: last_name)
      person.create_entity
      person.save!
      person
    end
  end
end
