# frozen_string_literal: true
class MeasurementListReader
  include ActiveModel::Model
  include ActiveRecord::AttributeAssignment

  attr_accessor :ministry_id, :mcc, :period, :source, :historical

  def initialize(attributes = {})
    super(attributes)

    # default values
    @period ||= Time.zone.today.strftime('%Y-%m')
    @source ||= 'gma-app'
  end

  def load
    raise if ministry_id.blank? || mcc.blank?

    @measurements = Measurement.where(mcc_filter: [nil, mcc])
    @measurements = filter_by_show_hide
    # it might be nice to run this each separate threads since they do 3 GR calls each
    # Spencer suggests waiting until we test how the performs
    # https://github.com/tra/spawnling might be a good option, or a vanilla thread pool
    # https://blog.engineyard.com/2014/ruby-thread-pool
    @measurements.each(&method(:load_gr_value))
    split_children
  end

  private

  def load_gr_value(measurement)
    return load_historic_gr_values(measurement) if historical
    levels = Power.current.try(:measurement_levels) || [:total, :local, :person]
    levels.each do |level|
      measurement_level_id = measurement.send("#{level}_id")
      filter_params = gr_request_params(level)
      gr_resp = GlobalRegistryClient.client(:measurement_type).find(measurement_level_id, filter_params)
      value = gr_resp['measurement_type']['measurements'].map { |m| m['value'].to_f }.sum
      measurement.send("#{level}=", value)
    end
  end

  def load_historic_gr_values(measurement)
    return unless can_historic
    gr_resp = GlobalRegistry::MeasurementType
              .find(measurement.total_id, gr_request_params(:total))['measurement_type']['measurements']
    measurement.total = build_total_hash(gr_resp)
  end

  def build_total_hash(gr_resp)
    total_hash = {}
    i_period = period_from
    loop do
      total_hash[i_period] = gr_resp.find { |m| m['period'] == i_period }.try(:[], 'value').to_f
      break if i_period == period
      i_period = (Date.parse("#{i_period}-01") + 1.month).strftime('%Y-%m')
    end
    total_hash
  end

  def gr_request_params(level)
    {
      'filters[related_entity_id]': ministry_id,
      'filters[period_from]': period_from,
      'filters[period_to]': period,
      'filters[dimension]': dimension_filter(level),
      per_page: 250
    }
  end

  def period_from
    return period unless historical && can_historic
    from = Date.parse("#{period}-01") - 11.months
    from.strftime('%Y-%m')
  end

  def can_historic
    Power.current.blank? || Power.current.historic_measurements
  end

  def dimension_filter(level)
    if level == :total
      mcc
    else
      "#{mcc}_#{source}"
    end
  end

  def filter_by_show_hide
    query = []
    query = [show_filter] if ministry.lmi_show.present?
    query << hide_filter if ministry.lmi_hide.present?
    if query.count == 2
      @measurements.where(query[0].or(query[1]))
    elsif query.count == 1
      @measurements.where(query[0])
    else
      @measurements
    end
  end

  def ministry
    Ministry.find_by(gr_id: ministry_id)
  end

  # show the custom measurements
  def show_filter
    perm_links = ministry.lmi_show.map { |lmi| "lmi_total_custom_#{lmi}" }
    table[:perm_link].in(perm_links)
  end

  # core measurements to hide
  def hide_filter
    perm_links = ministry.lmi_hide.map { |lmi| "lmi_total_#{lmi}" }
    table[:perm_link].does_not_match('%_custom_%').and(table[:perm_link].not_in(perm_links))
  end

  def table
    Measurement.arel_table
  end

  def split_children
    @measurements.select do |meas|
      # use select instead since we already have them loaded in memory
      children = @measurements.select { |child| child.parent_id == meas.id }
      meas.loaded_children = children
      next meas if meas.parent_id.blank?
    end
  end
end
