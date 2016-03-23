# frozen_string_literal: true
class Measurement < ActiveRecord::Base
  belongs_to :parent, class_name: 'Measurement'
  has_many :children, class_name: 'Measurement', foreign_key: :parent_id
  has_many :measurement_translations

  validates :person_id, presence: true
  validates :local_id, presence: true
  validates :total_id, presence: true

  attr_accessor :total, :local, :person, :loaded_children

  def initialize(attributes = nil, options = {})
    super(attributes, options)
    @translations = {}
  end

  def perm_link_stub
    perm_link.sub('lmi_total_custom_', '').sub('lmi_total_', '')
  end

  def localized_name(language, ministry)
    translation = translation_for(language, ministry)
    return english unless translation
    translation.name
  end

  def localized_description(language, ministry)
    translation = translation_for(language, ministry)
    return description unless translation
    translation.description
  end

  def locale(language, ministry)
    return language if translation_for language, ministry
    'en'
  end

  def translation_for(language, ministry)
    return unless language && ministry
    @translations ||= {}
    key = "#{language}-#{ministry}"
    return @translations[key] if @translations.key? key
    ministry = Ministry.find_by(id: ministry) unless ministry.is_a? Ministry
    return @translations[key] = nil unless ministry
    ministry = ministry.self_and_ancestors.joins(:measurement_translations).reorder(lft: :desc)
                       .find_by(measurement_translations: { language: language, measurement_id: id })
    @translations[key] = measurement_translations.find_by(language: language, ministry: ministry)
  end

  def self.find_by_perm_link(perm_link)
    perm_link = perm_link.sub('lmi_total_custom_', '').sub('lmi_total_', '')
    find_by(perm_link: ["lmi_total_#{perm_link}", "lmi_total_custom_#{perm_link}"])
  end

  def load_gr_value(params)
    @gr_loading_params = params
    return load_historic_gr_values if @gr_loading_params[:historical]
    @gr_loading_params[:levels].each do |level|
      measurement_level_id = send("#{level}_id")
      filter_params = gr_request_params(level)
      gr_resp = GlobalRegistryClient.client(:measurement_type).find(measurement_level_id, filter_params)
      value = gr_resp['measurement_type']['measurements'].map { |m| m['value'].to_f }.sum
      send("#{level}=", value)
    end
  end

  private

  def load_historic_gr_values
    return unless can_historic
    gr_resp = GlobalRegistry::MeasurementType
              .find(total_id, gr_request_params(:total))['measurement_type']['measurements']
    @total = build_total_hash(gr_resp)
  end

  def build_total_hash(gr_resp)
    total_hash = {}
    i_period = period_from
    loop do
      total_hash[i_period] = gr_resp.find { |m| m['period'] == i_period }.try(:[], 'value').to_f
      break if i_period == @gr_loading_params[:period]
      i_period = (Date.parse("#{i_period}-01") + 1.month).strftime('%Y-%m')
    end
    total_hash
  end

  def gr_request_params(level)
    {
      'filters[related_entity_id]': @gr_loading_params[:ministry_id],
      'filters[period_from]': period_from,
      'filters[period_to]': @gr_loading_params[:period],
      'filters[dimension]': dimension_filter(level),
      per_page: 250
    }
  end

  def period_from
    return @gr_loading_params[:period] unless @gr_loading_params[:historical] && can_historic
    from = Date.parse("#{@gr_loading_params[:period]}-01") - 11.months
    from.strftime('%Y-%m')
  end

  def can_historic
    Power.current.blank? || Power.current.historic_measurements
  end

  def dimension_filter(level)
    if level == :total
      @gr_loading_params[:mcc]
    else
      "#{@gr_loading_params[:mcc]}_#{@gr_loading_params[:source]}"
    end
  end
end
