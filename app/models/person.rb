class Person < ActiveRecord::Base
  include GlobalRegistry::EntityMethods

  has_many :user_content_locales, foreign_key: :person_id, primary_key: :person_id, dependent: :destroy
  has_many :user_map_views, foreign_key: :person_id, primary_key: :person_id, dependent: :destroy
  has_many :user_measurement_states, foreign_key: :person_id, primary_key: :person_id, dependent: :destroy
  has_many :user_preferences, foreign_key: :person_id, primary_key: :person_id, dependent: :destroy

  # Map GR key_username to cas_username
  alias_attribute :key_username, :cas_username

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

  # rubocop:disable Metrics/AbcSize
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
  # rubocop:enable Metrics/AbcSize

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
    self.user_content_locales = content_locales
  end

  def attribute_from_entity_property(property, value = nil)
    self.person_id = value and return if property.eql? :id
    super
  end

  def self.entity_type
    'person'
  end

  # Global Registry Entity Properties to sync
  def self.entity_properties
    [:first_name, :last_name, :key_username, :authentication].concat(super)
  end

  def self.find_or_initialize(guid, refresh = false)
    person = find_by(cas_guid: guid)
    if person.nil? || refresh
      person = new(cas_guid: guid) if person.nil?
      entity = find_entity_by_key_guid guid
      return if entity.nil?
      person.from_entity entity
      person.save
    end
    person
  end

  def self.find_entity_by_key_guid(guid)
    results = GlobalRegistry::Entity.get(
      entity_type: 'person',
      fields: 'first_name,last_name,key_username,authentication.key_guid',
      'filters[authentication][key_guid]': guid
    )['entities']
    return nil unless results[0] && results[0]['person']
    results[0].with_indifferent_access
  end
end
