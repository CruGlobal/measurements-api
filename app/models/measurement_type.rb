# frozen_string_literal: true

class MeasurementType < ActiveModelSerializers::Model
  include ActiveModel::Model
  include ActiveSupport::Callbacks
  include ActiveModel::Validations::Callbacks
  include ActiveRecord::AttributeAssignment
  define_callbacks :save

  ATTRIBUTES = [:english, :perm_link_stub, :description, :section, :column, :sort_order, :parent_id,
                :localized_name, :localized_description, :ministry_id, :locale, :measurement, :is_core,].freeze
  attr_accessor(*ATTRIBUTES)

  validate :check_parent_id_valid

  MINISTRY_TYPE_ID = ENV["MINISTRY_TYPE_ID"]
  ASSIGNMENT_TYPE_ID = ENV["ASSIGNMENT_TYPE_ID"]

  def save
    return false unless valid?

    Measurement.transaction do
      send_gr_measurement_types
      build_measurement
      return false unless measurement.valid?
      build_translation if can_build_trans
      measurement.save!
      @translation&.save!
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
      mt = new(args.merge(measurement: measurement))
      mt.load_parent_translation
      mt
    end
  end

  def new_record?
    return true if measurement.blank?
    measurement.new_record?
  end

  def destroy
    return unless measurement
    raise "measurements with children can not be destroyed" if measurement.children.any?

    gr_singleton.delete(measurement.total_id)
    gr_singleton.delete(measurement.local_id)
    gr_singleton.delete(measurement.person_id)

    measurement.destroy
  end

  def load_parent_translation
    return unless @measurement && @ministry_id && @locale
    @translation = @measurement.translation_for(@locale, @ministry_id)
    if @translation
      @localized_name = @translation.name
      @localized_description = @translation.description
    else
      @localized_name = @measurement.english
      @localized_description = @measurement.description
    end
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
      section: section || "other",
      column: column || "other",
      parent_id: parent_id,
    }.compact
  end

  def gen_perm_link(perm_link_prefix = "total")
    self.is_core = ActiveRecord::Type::Boolean.new.cast(is_core)
    perm_link_prefix = "#{perm_link_prefix}_" unless perm_link_prefix.blank? || perm_link_prefix.end_with?("_")
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
      ministry_id: ministry_id,
    }.compact
  end

  def check_parent_id_valid
    return if parent_id.blank? || parent_id.is_a?(Integer)
    parent = Measurement.find_by(total_id: parent_id)
    parent ||= Measurement.find_by_perm_link(perm_link_stub)
    self.parent_id = parent.try(:id)
  end

  def send_gr_measurement_types
    return unless measurement.blank? || measurement.new_record?

    @total_id = send_gr_measurement_type(nil, "total", MINISTRY_TYPE_ID)
    @local_id = send_gr_measurement_type("Local", "local", MINISTRY_TYPE_ID)
    @person_id = send_gr_measurement_type("Person", nil, ASSIGNMENT_TYPE_ID)
  end

  def send_gr_measurement_type(name_type, perm_link_prefix, related_id)
    name = english
    name = "#{english} (#{name_type})" if name_type

    perm_link = gen_perm_link(perm_link_prefix || "")
    json = gr_singleton.post(measurement_type: {name: name, frequency: "monthly", unit: "People",
                                                description: description, perm_link: perm_link,
                                                related_entity_type_id: related_id,})
    json["measurement_type"]["id"]
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
    GlobalRegistryClient.client(:measurement_type)
  end
end
