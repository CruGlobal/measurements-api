class Person < ActiveRecord::Base
  has_many :user_content_locales, foreign_key: :person_id, primary_key: :person_id, dependent: :destroy
  has_many :user_map_views, foreign_key: :person_id, primary_key: :person_id, dependent: :destroy
  has_many :user_measurement_states, foreign_key: :person_id, primary_key: :person_id, dependent: :destroy
  has_many :user_preferences, foreign_key: :person_id, primary_key: :person_id, dependent: :destroy

  class << self
    def find_or_initialize(guid)
      person = Person.find_by(cas_guid: guid)
      return person if person
      gr_person = GlobalRegistry::Person.find_by_key_guid(guid)
      Person.create(
        person_id: gr_person.id,
        first_name: gr_person.first_name,
        last_name: gr_person.last_name,
        cas_guid: guid,
        cas_username: gr_person.key_username
      ) if gr_person
    end
  end
end
