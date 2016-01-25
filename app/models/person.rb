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

  def add_or_update_preference(name, value)
    # Creates or updates a user_preference, deletes if value is nil
    pref = user_preferences.find_by(name: name) # where(name: name).first
    if value.nil?
      user_preferences.destroy(pref) if pref
    else
      pref ||= user_preferences.build(name: name)
      pref.attributes = { value: value }
      pref.save
    end
  end

  def add_or_update_map_views(value)
    user_map_views.clear and return if value.nil?
    value.each do |view|
      map_view = user_map_views.find_by ministry_id: view['ministry_id']
      map_view ||= user_map_views.build ministry_id: view['ministry_id']
      map_view.attributes = {
        lat: view['location']['latitude'],
        long: view['location']['longitude'],
        zoom: view['location_zoom']
      }
      map_view.save
    end
  end

  def add_or_update_measurement_states(value)
    user_measurement_states.clear and return if value.nil?
    value.each do |mcc, perm_link_stubs|
      perm_link_stubs.each do |perm_link_stub, visible|
        state = user_measurement_states.find_by(mcc: mcc, perm_link_stub: perm_link_stub)
        state ||= user_measurement_states.build(mcc: mcc, perm_link_stub: perm_link_stub)
        state.attributes = { visible: visible == 1 }
        state.save
      end
    end
  end

  def add_or_update_content_locales(value)
    user_content_locales.clear and return if value.nil?
    content_locales = []
    value.each do |ministry_id, locale|
      content_locale = user_content_locales.find_by(ministry_id: ministry_id)
      content_locale ||= user_content_locales.build(ministry_id: ministry_id)
      content_locale.attributes = { locale: locale }
      content_locales << content_locale
    end
    user_content_locales = content_locales
  end
end
