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
    @measurements = filter_by_show_hide
    @measurements.each(&method(:load_gr_value))
  end

  private

  def load_gr_value(measurement)
    levels = Power.current.try(:measurement_levels) || [:total, :local, :person]
    levels.each do |level|
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
end
