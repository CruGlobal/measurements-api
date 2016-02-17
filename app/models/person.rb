class Person < ActiveRecord::Base # rubocop:disable Metrics/ClassLength
  include GlobalRegistry::EntityMethods

  has_many :user_content_locales, foreign_key: :person_id, primary_key: :person_id, dependent: :destroy
  has_many :user_map_views, foreign_key: :person_id, primary_key: :person_id, dependent: :destroy
  has_many :user_measurement_states, foreign_key: :person_id, primary_key: :person_id, dependent: :destroy
  has_many :user_preferences, foreign_key: :person_id, primary_key: :person_id, dependent: :destroy

  has_many :assignments, foreign_key: :person_id, primary_key: :person_id, dependent: :destroy, inverse_of: :ministry
  has_many :ministries, through: :assignments

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
    self.user_content_locales = content_locales
  end

  def attribute_from_entity_property(property, value = nil)
    case property.to_sym
    when :id
      self.person_id = value
    when :authentication
      auth = value.with_indifferent_access
      self.cas_guid = auth[:key_guid] if auth.key? :key_guid
    else
      super
    end
  end

  def assignment_for_ministry(ministry_id)
    assignments.find_by(ministry_id: ministry_id)
  end

  def role_for_ministry(ministry_id)
    assignment_for_ministry(ministry_id).try(:role)
  end

  def self.entity_type
    'person'
  end

  # Global Registry Entity Properties to sync
  def self.entity_properties
    [:first_name, :last_name, :key_username, :authentication].concat(super)
  end

  def self.person(guid, refresh = false)
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

  def self.person_for_username(username, refresh = false)
    person = find_by(cas_username: username)
    if person.nil? || refresh
      person = new if person.nil?
      entity = find_entity_by(
        entity_type: entity_type,
        fields: 'first_name,last_name,key_username,authentication.key_guid',
        'filters[key_username]': username
      )
      return if entity.nil?
      person.from_entity entity
      person.save
    end
    person
  end

  def self.find_entity_by_key_guid(guid)
    find_entity_by(
      entity_type: entity_type,
      fields: 'first_name,last_name,key_username,authentication.key_guid',
      'filters[authentication][key_guid]': guid
    )
  end

  def full_name
    "#{first_name} #{last_name}"
  end
end
