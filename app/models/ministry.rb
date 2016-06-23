# frozen_string_literal: true
class Ministry < ActiveRecord::Base # rubocop:disable Metrics/ClassLength
  # Valid MCCs (Mission Critical Components)
  MCC_SLM = 'slm'
  MCC_LLM = 'llm'
  MCC_GCM = 'gcm'
  MCC_DS = 'ds'
  MCCS = [MCC_SLM, MCC_LLM, MCC_GCM, MCC_DS].freeze

  # Map global registry mcc property names to MCC value
  ENTITY_MCCS = {
    has_slm: MCC_SLM,
    has_llm: MCC_LLM,
    has_gcm: MCC_GCM,
    has_ds: MCC_DS
  }.freeze

  # WHQ Scopes
  SCOPES = %w(National Area Global National\ Region).freeze

  PERMITTED_PARAMS = [:name, :parent_id, :min_code, :ministry_scope, :default_mcc, :hide_reports_tab,
                      :location_zoom, location: [:latitude, :longitude], lmi_show: [], lmi_hide: [], mccs: []].freeze

  include GrSync::EntityMethods

  acts_as_nested_set dependent: :nullify

  scope :inherited_ministries, lambda { |person|
    joins(inherited_ministry_join)
      .joins(assignment_join)
      .where(assignments: { person_id: person.id })
      .where(assignments: Assignment.local_leader_condition)
      .distinct
  }

  has_many :assignments, dependent: :destroy, inverse_of: :ministry
  has_many :people, through: :assignments
  has_many :measurement_translations

  has_many :user_content_locales, dependent: :destroy
  has_many :stories, dependent: :destroy
  belongs_to :area

  auto_strip_attributes :name

  validates :name, presence: true
  validates :default_mcc, inclusion: { in: MCCS, message: '\'%{value}\' is not a valid MCC' },
                          unless: 'default_mcc.blank?'
  validates :min_code, uniqueness: true, on: :create, if: 'min_code.present?'
  before_validation :generate_min_code, on: :create, if: 'gr_id.blank?'
  before_create :create_entity, if: 'gr_id.blank?'

  authorize_values_for :parent_id, message: 'Only leaders of both ministries may move a ministry'

  # Find Ministry by gr_id, update from Global Registry if nil or refresh is true
  def self.ministry(gr_id, refresh = false)
    ministry = find_by(gr_id: gr_id)
    if ministry.nil? || refresh
      ministry = new(gr_id: gr_id) if ministry.nil?
      entity = ministry.update_from_entity(fields: '*,area:relationship')
      return nil if entity.nil?
      ministry.save
      ministry.sync_assignments
    end
    ministry
  end

  def sync_assignments
    entity = Ministry.find_entity(gr_id, 'fields' => 'person:relationship',
                                         'filters[owned_by]' => ENV.fetch('GLOBAL_REGISTRY_SYSTEM_ID'))
               &.dig(self.class.entity_type)
    GrSync::MultiAssignmentSync.new(self, entity).sync
  rescue Net::HTTPGatewayTimeOut
    # India and US-Student Ministries timeout
    nil
  end

  def team_members # rubocop:disable Metrics/AbcSize
    members = {}
    Assignment.ancestor_assignments(self).each do |assignment|
      # Direct Assignments take precedence
      members[assignment.person_id] = assignment if assignment.ministry_id == id
      # Next if direct assignment and it's not inherited
      next if members[assignment.person_id].try(:ministry_id) == id &&
              !members[assignment.person_id].try(:inherited_role?)

      # Keep highest Inherited assignment per person
      if members[assignment.person_id].blank? || members[assignment.person_id].try(:[], :role) < assignment[:role]
        members[assignment.person_id] = assignment.as_inherited_assignment(id)
      end
    end
    members.values
  end

  # Find first ancestor ministry with a ministry scope
  def parent_whq_ministry
    ancestors.order(lft: :desc).find_by(ministry_scope: SCOPES)
  end

  # Prefix new ministries min_code with parent min_code if WHQ ministry
  def generate_min_code
    self.min_code = name if min_code.blank?
    return unless min_code.is_a? String
    self.min_code = min_code.downcase.gsub(/\s+/, '_')
    ministry = parent_whq_ministry
    self.min_code = [ministry.min_code, min_code].join('_') unless ministry.nil?
  end

  def from_entity(entity = {})
    entity = super(entity)
    assign_area_from_entity(entity)
    entity
  end

  # Getter/Setters for GR
  def location=(value)
    self.latitude = value[:latitude] if value.key? :latitude
    self.longitude = value[:longitude] if value.key? :longitude
  end

  def location
    # TODO: walk parent ministries to find lat/lng if missing
    { latitude: latitude, longitude: longitude }
  end

  def lmi_show=(lmi)
    lmi = lmi.split(',') if lmi.is_a? String
    super lmi
  end

  def lmi_hide=(lmi)
    lmi = lmi.split(',') if lmi.is_a? String
    super lmi
  end

  private

  # Model attribute value to Global Registry Entity property value
  # Return nil to remove property from the request
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength
  def attribute_to_entity_property(property)
    case property.to_sym
    when :id
      gr_id
    when :parent_id
      parent.try(:gr_id)
    when :client_integration_id
      min_code
    when :has_ds, :has_llm, :has_gcm, :has_slm
      mcc = ENTITY_MCCS[property]
      mccs.include? mcc
    when :lmi_show
      lmi_show.empty? ? nil : lmi_show.join(',')
    when :lmi_hide
      lmi_hide.empty? ? nil : lmi_hide.join(',')
    when :location
      loc = location
      loc.delete_if { |_k, v| v.nil? }
      return nil if loc.empty?
      loc[:client_integration_id] = min_code
      loc
    else
      super
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength

  # Set self attribute value from Global Registry Entity property and value
  def attribute_from_entity_property(property, value = nil) # rubocop:disable Metrics/MethodLength
    case property.to_sym
    when :id
      super(:gr_id, value)
    when :parent_id
      self.parent_gr_id = value
      super(:parent_id, self.class.find_by(gr_id: value).try(:id))
    when :has_ds, :has_llm, :has_gcm, :has_slm
      mcc = ENTITY_MCCS[property]
      if value
        mccs << mcc unless mccs.include? mcc
      else
        mccs.delete mcc
      end
    else
      super(property, value)
    end
  end

  def assign_area_from_entity(entity)
    relationship = entity&.dig('area:relationship')
    # area:relationship could be an array in the rare case of an ministry that
    # is in two ares. We are choosing not to model that case in our
    # application (just assuming all ministries have one area), but to prevent
    # an error, just take the first of multiople possible areas from global
    # registry.
    area_gr_id = Array.wrap(relationship).first&.dig('area')
    return unless area_gr_id
    self.area = Area.for_gr_id(area_gr_id)
  end

  class << self
    # Global Registry Entity type
    def entity_type
      'ministry'
    end

    # Global Registry Entity Properties to sync
    def entity_properties
      [:name, :parent_id, :min_code, :location, :location_zoom, :lmi_hide, :lmi_show,
       :has_slm, :has_llm, :has_gcm, :has_ds, :ministry_scope].concat(super)
    end

    private

    # Arel methods
    def inherited_ministry_join
      arel_table
        .join(arel_table.alias('self'))
        .on(inherited_left_condition.and(inherited_right_condition))
        .join_sources
    end

    def inherited_left_condition
      arel_table.alias('self')[left_column_name].lteq(arel_table[left_column_name])
    end

    def inherited_right_condition
      arel_table.alias('self')[right_column_name].gteq(arel_table[right_column_name])
    end

    def assignment_join
      arel_table
        .join(Assignment.arel_table)
        .on(Assignment.arel_table[:ministry_id].eq(arel_table.alias('self')[:id]))
        .join_sources
    end
  end
end
