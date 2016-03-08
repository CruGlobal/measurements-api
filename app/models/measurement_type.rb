class MeasurementType < ActiveModelSerializers::Model
  include ActiveModel::Model
  include ActiveSupport::Callbacks
  include ActiveModel::Validations::Callbacks
  include ActiveRecord::AttributeAssignment
  define_callbacks :save

  ATTRIBUTES = [:english, :perm_link_stub, :description, :section, :column, :sort_order, :parent_id,
                :localized_name, :localized_description, :ministry_id, :locale, :measurement, :is_core].freeze
  attr_accessor(*ATTRIBUTES)

  validates :english, presence: { message: "Could not find required field: 'english'" }
  validates :perm_link_stub, presence: { message: "Could not find required field: 'perm_link_stub'" }
  validate :check_perm_link_start, :check_perm_link_unique, :check_parent_id_valid

  MINISTRY_TYPE_ID = 'a5499c9a-d556-11e3-af5a-12725f8f377c'.freeze
  ASSIGNMENT_TYPE_ID = 'b4c69f8e-db86-11e3-acf9-12725f8f377c'.freeze

  def save
    return false unless valid?

    Measurement.transaction do
      send_gr_measurement_types
      build_measurement
      return false unless measurement.valid?
      build_translation if can_build_trans
      measurement.save!
      @translation.save! if @translation
      true
    end
  rescue
    false
  end

  def initialize(attributes = {})
    if attributes[:measurement]
      meas_attributes = attributes[:measurement].attributes.symbolize_keys.slice(*ATTRIBUTES)
      attributes = meas_attributes.merge(attributes)
      attributes[:perm_link_stub] ||= attributes[:measurement].perm_link_stub
    end
    super(attributes)
    build_translation if measurement.present?
  end

  def self.all_localized_with(args)
    Measurement.all.map do |measurement|
      new(args.merge(measurement: measurement))
    end
  end

  def new_record?
    return true if measurement.blank?
    measurement.new_record?
  end

  private

  def build_measurement
    self.measurement ||= Measurement.new
    measurement.attributes = if measurement.new_record?
                               measurement_attributes
                             else
                               measurement_attributes.except(:perm_link)
                             end
  end

  def measurement_attributes
    {
      english: english,
      description: description,
      perm_link: gen_perm_link,
      sort_order: sort_order || 90,
      total_id: @total_id,
      local_id: @local_id,
      person_id: @person_id,
      section: section || 'other',
      column: column || 'other',
      parent_id: parent_id
    }.compact
  end

  def gen_perm_link(perm_link_prefix = 'total')
    self.is_core = ActiveRecord::Type::Boolean.new.type_cast_from_user(is_core)
    perm_link_prefix = "#{perm_link_prefix}_" unless perm_link_prefix.blank? || perm_link_prefix.end_with?('_')
    if is_core
      "lmi_#{perm_link_prefix}#{perm_link_stub}"
    else
      "lmi_#{perm_link_prefix}custom_#{perm_link_stub}"
    end
  end

  def build_translation
    @translation ||= measurement.measurement_translations.find_or_initialize_by(ministry_id: ministry_id,
                                                                                language: locale)
    @translation.attributes = translation_attributes
    self.localized_name ||= @translation.name
    self.localized_description ||= @translation.description
  end

  def translation_attributes
    {
      name: localized_name,
      description: localized_description,
      language: locale,
      ministry_id: ministry_id
    }.compact
  end

  def check_perm_link_start
    %w(local_ total_ custom_).each do |start|
      if perm_link_stub.downcase.start_with?(start)
        errors.add(:perm_link_stub, " is invalid. It cannot start with: '#{start}'")
      end
    end
  end

  def check_perm_link_unique
    matching_measurement = Measurement.find_by_perm_link(perm_link_stub)
    return unless matching_measurement && matching_measurement.id != measurement.id

    errors.add(:perm_link_stub, 'perm_link_stub is being used by another measurement_type. It must be unique.')
  end

  def check_parent_id_valid
    return if parent_id.blank? || parent_id.is_a?(Integer)
    parent = Measurement.find_by(total_id: parent_id)
    parent ||= Measurement.find_by_perm_link(perm_link_stub)
    self.parent_id = parent.try(:id)
  end

  def send_gr_measurement_types
    return unless measurement.blank? || measurement.new_record?

    @total_id = send_gr_measurement_type(nil, 'total', MINISTRY_TYPE_ID)
    @local_id = send_gr_measurement_type('Local', 'local', MINISTRY_TYPE_ID)
    @person_id = send_gr_measurement_type('Person', nil, ASSIGNMENT_TYPE_ID)
  end

  def send_gr_measurement_type(name_type, perm_link_prefix, related_id)
    name = english
    name = "#{english} (#{name_type})" if name_type

    perm_link = gen_perm_link(perm_link_prefix || '')
    json = gr_singleton.post(name: name, frequency: 'monthly', unit: 'People',
                             description: description, perm_link: perm_link,
                             related_entity_type_id: related_id)
    json['measurement_type']['id']
  end

  def ensure_type_ids_present
    if measurement.present?
      measurement.total_id.present? && measurement.local_id.present? && measurement.person_id.present?
    else
      @total_id.present? && @local_id.present? && @person_id.present?
    end
  end

  def can_build_trans
    true unless ministry_id.blank? || (localized_name.blank? && localized_description.blank?)
  end

  def gr_singleton
    GlobalRegistry::MeasurementType.new(GlobalRegistryParameters.current)
  end
end
