# frozen_string_literal: true
class Person < ActiveRecord::Base # rubocop:disable Metrics/ClassLength
  include GrSync::EntityMethods

  GR_FIELDS = 'first_name,last_name,key_username,authentication,email_address.email'

  has_many :user_content_locales, dependent: :destroy
  has_many :user_map_views, dependent: :destroy
  has_many :user_measurement_states, dependent: :destroy
  has_many :user_preferences, dependent: :destroy

  has_many :assignments, dependent: :destroy, inverse_of: :person
  has_many :ministries, through: :assignments
  has_many :stories, foreign_key: :created_by_id, dependent: :destroy

  # Map GR key_username to cas_username
  alias_attribute :key_username, :cas_username

  def attribute_to_entity_property(property)
    case property.to_sym
    when :id
      nil
    when :authentication
      { key_guid: cas_guid } if cas_guid.present?
    when :email_address
      [{ email: email, client_integration_id: email }] if email.present?
    else
      super
    end
  end

  def client_integration_id
    return cas_guid if cas_guid.present?
    return ea_guid if ea_guid.present?
    return email if email.present?
    id
  end

  def attribute_from_entity_property(property, value = nil)
    case property.to_sym
    when :id
      self.gr_id = value
    when :authentication
      auth = value.with_indifferent_access
      self.cas_guid = auth[:key_guid] if auth.key? :key_guid
      self.ea_guid = auth[:ea_guid] if auth.key? :ea_guid
    when :email_address
      email_address = Array.wrap(value).first
      self.email = email_address['email'] if email_address.key? 'email'
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

  class << self
    def entity_type
      'person'
    end

    # Global Registry Entity Properties to sync
    def entity_properties
      [:first_name, :last_name, :key_username, :authentication,
       :email_address, :preferred_name].concat(super)
    end

    def person(cas_guid, refresh = false)
      person_for_auth_guid(:cas, :key, cas_guid, refresh)
    end

    def person_for_ea_guid(ea_guid, refresh = false)
      person_for_auth_guid(:ea, :ea, ea_guid, refresh)
    end

    def person_for_username(username, refresh = false)
      person = find_by(cas_username: username)
      if person.nil? || refresh
        entity = find_entity_by(
          entity_type: entity_type,
          fields: GR_FIELDS,
          'filters[key_username]': username
        )
        return person if entity.nil?
        person = Person.find_or_initialize_by(gr_id: entity['person']['id']) if person.nil?
        person.from_entity entity
        person.save
      end
      person
    end

    def person_for_email(email, refresh = false)
      person = find_by(email: email)
      if person.nil? || refresh
        entity = find_entity_by(
          entity_type: entity_type,
          fields: GR_FIELDS,
          'filters[email_address][email]': email
        )
        return person if entity.nil?
        person = Person.find_or_initialize_by(gr_id: entity['person']['id']) if person.nil?
        person.from_entity entity
        person.save
      end
      person
    end

    def person_for_gr_id(gr_id)
      return if gr_id.blank?
      person = Person.find_by(gr_id: gr_id)
      return person if person
      entity = Person.find_entity(gr_id, entity_type: 'person')
      person = Person.find_or_initialize_by(gr_id: gr_id)
      person.from_entity(entity)
      person.save
      person
    end

    private

    def person_for_auth_guid(guid_field_prefix, gr_auth_prefix, guid, refresh)
      return if guid.blank?
      guid_field = "#{guid_field_prefix}_guid"
      person = find_by(guid_field => guid)
      return person unless person.nil? || refresh

      entity = find_entity_by_auth_guid(gr_auth_prefix, guid)
      return if entity.nil?
      person = find_or_initialize_by(gr_id: entity['person']['id'])
      person.send("#{guid_field}=", guid)
      person.from_entity entity
      person.save
      person
    end

    def find_entity_by_auth_guid(gr_auth_prefix, guid)
      # When using authentication, we find by posting
      client.post({ entity: { person: { authentication: { "#{gr_auth_prefix}_guid" => guid },
                                        client_integration_id: guid } } },
                  params: { fields: GR_FIELDS, full_response: 'true' })['entity']
    end
  end
end
