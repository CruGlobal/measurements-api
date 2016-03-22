# frozen_string_literal: true
class Person < ActiveRecord::Base
  include GrSync::EntityMethods

  has_many :user_content_locales, dependent: :destroy
  has_many :user_map_views, dependent: :destroy
  has_many :user_measurement_states, dependent: :destroy
  has_many :user_preferences, dependent: :destroy

  has_many :assignments, dependent: :destroy, inverse_of: :person
  has_many :ministries, through: :assignments
  has_many :stories, foreign_key: :created_by_id, dependent: :destroy

  # Map GR key_username to cas_username
  alias_attribute :key_username, :cas_username

  def attribute_from_entity_property(property, value = nil)
    case property.to_sym
    when :id
      self.gr_id = value
    when :authentication
      auth = value.with_indifferent_access
      self.cas_guid = auth[:key_guid] if auth.key? :key_guid
    else
      super
    end
  end

  def assignment_for_ministry(ministry)
    ministry = ministry_param ministry
    return unless ministry.present?
    assignments.find_by(ministry: ministry)
  end

  def inherited_assignment_for_ministry(ministry)
    ministry = ministry_param ministry
    return unless ministry.present?
    ancestor = ministry.self_and_ancestors.joins(:assignments)
                       .where(assignments: { person_id: id }.merge(Assignment.local_leader_condition))
                       .order('assignments.role DESC').first
    return unless ancestor
    assignment = assignment_for_ministry(ancestor)
    assignment.as_inherited_assignment(ministry.id) if assignment
  end

  def role_for_ministry(ministry)
    assignment_for_ministry(ministry).try(:role)
  end

  def inherited_role_for_ministry(ministry)
    inherited_assignment_for_ministry(ministry).try(:role)
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

  def self.person_for_gr_id(gr_id)
    person = Person.find_by(gr_id: gr_id)
    return person if person
    entity = Person.find_entity(gr_id, entity_type: 'person')
    person = Person.new
    person.from_entity(entity)
    person.save
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

  private

  # Return Ministry by id or uuid with Global Registry fallback
  def ministry_param(ministry)
    if ministry.is_a? Integer
      Ministry.find_by(id: ministry)
    elsif Uuid.uuid? ministry
      Ministry.ministry(ministry)
    elsif ministry.is_a? Ministry
      ministry
    end
  end
end
