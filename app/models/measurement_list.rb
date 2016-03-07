class MeasurementList
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
    @measurements.each(&method(:load_gr_value))
  end

  private

  def load_gr_value(measurement)
    Power.current.measurement_levels.each do |level|
      measurement_level_id = measurement.send("#{level}_id")
      filter_params = {
        'filters[related_entity_id]': ministry_id,
        'filters[period_from]': period_from,
        'filters[period_to]': period,
        'filters[dimension]': dimension_filter(level),
        per_page: 250
      }
      gr_resp = GlobalRegistry::MeasurementType.find(measurement_level_id, filter_params)
      value = gr_resp['measurement_type']['measurements'].first.try(:[], 'value')
      measurement.send("#{level}=", value.to_f)
    end
  end

  def period_from
    return period unless historical
    from = Date.parse("#{period}-01") - 11.months
    from.strftime('%Y-%m')
  end

  def dimension_filter(level)
    if level == :total
      mcc
    else
      "#{mcc}_#{source}"
    end
  end
end
