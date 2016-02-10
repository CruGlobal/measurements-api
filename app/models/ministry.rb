class Ministry < ActiveRecord::Base # rubocop:disable Metrics/ClassLength
  include GlobalRegistry::EntityMethods

  # Map global registry mcc property names to MCC value
  ENTITY_MCCS = {
    has_slm: Constants::MCC_SLM,
    has_llm: Constants::MCC_LLM,
    has_gcm: Constants::MCC_GCM,
    has_ds: Constants::MCC_DS
  }.freeze

  has_one :parent, primary_key: :parent_id, foreign_key: :ministry_id, class_name: 'Ministry'
  belongs_to :children, primary_key: :ministry_id, foreign_key: :parent_id, class_name: 'Ministry'

  has_many :assignments, foreign_key: :ministry_id, primary_key: :ministry_id, dependent: :destroy, inverse_of: :person
  has_many :people, through: :assignments

  auto_strip_attributes :name

  validates :name, presence: true
  validates :min_code, uniqueness: true, on: :create
  validates :default_mcc, inclusion: { in: Constants::MCCS, message: '\'%{value}\' is not a valid MCC' },
                          unless: 'default_mcc.blank?'

  before_validation :generate_min_code, on: :create, if: 'ministry_id.blank?'

  before_create :create_entity, if: 'ministry_id.blank?'

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

  # Override relationship to load parent ministry from GR if not cached
  def parent(force_reload = false)
    return nil if parent_id.nil?
    parent_ministry = super
    Ministry.ministry(parent_id, true) if parent_ministry.nil?
    super true
  end

  # Find Ministry by ministry_id, update from Global Registry if nil or refresh is true
  # rubocop:disable Metrics/CyclomaticComplexity
  def self.ministry(ministry_id, refresh = false)
    ministry = find_by_ministry_id ministry_id
    if ministry.nil? || refresh
      ministry = new(ministry_id: ministry_id) if ministry.nil?
      entity = ministry.update_from_entity
      return nil if entity.nil? || (entity.key?(:is_active) && entity[:is_active] == false)
      ministry.save
    end
    ministry
  end

  # rubocop:enable Metrics/CyclomaticComplexity

  # Global Registry Entity type
  def self.entity_type
    'ministry'
  end

  # Global Registry Entity Properties to sync
  def self.entity_properties
    [:name, :parent_id, :min_code, :location, :location_zoom, :lmi_hide, :lmi_show,
     :hide_reports_tab, :has_slm, :has_llm, :has_gcm, :has_ds].concat(super)
  end

  # Model attribute value to Global Registry Entity property value
  # Return nil to remove property from the request
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength
  def attribute_to_entity_property(property)
    case property.to_sym
    when :id
      ministry_id
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
  def attribute_from_entity_property(property, value = nil)
    case property.to_sym
    when :id
      super(:ministry_id, value)
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

  def self.all_gr_ministries
    fail 'block required' unless block_given?
    all_active_ministries do |entity|
      yield entity
    end
    all_ministries_missing_active do |entity|
      yield entity
    end
  end

  # Find id, name for all active ministries
  def self.all_active_ministries
    fail 'block required' unless block_given?
    find_entities_each(
      entity_type: 'ministry',
      levels: 0,
      fields: 'name',
      'filters[parent_id:exists]': true,
      'filters[is_active]': true
    ) do |entity|
      yield entity
    end
  end

  # Find id, name for all ministries missing the active property
  def self.all_ministries_missing_active
    fail 'block required' unless block_given?
    find_entities_each(
      entity_type: 'ministry',
      levels: 0,
      fields: 'name',
      'filters[parent_id:exists]': true,
      'filters[is_active:not_exists]': true
    ) do |entity|
      yield entity
    end
  end

  protected

  # Filter to create Global Registry Entity before creating ActiveRecord entry
  def create_entity
    entity = super
    # update ministry_id from GR entity id
    self.ministry_id = entity[:id]
  end

  # Prefix new ministries min_code with parent min_code if WHQ ministry
  def generate_min_code
    self.min_code = min_code.downcase.gsub(/\s+/, '_')
    ministry = parent_whq_ministry(parent)
    self.min_code = [ministry.min_code, min_code].join('_') unless ministry.nil?
  end

  # Walks ministry ancestors until it finds a ministry with a WHQ scope
  def parent_whq_ministry(ministry = nil)
    return nil if ministry.nil?
    return ministry if Constants::SCOPES.include?(ministry.ministry_scope)
    parent_whq_ministry(ministry.parent)
  end
end
