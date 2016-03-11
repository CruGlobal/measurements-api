class MeasurementDetails < ActiveModelSerializers::Model
  include ActiveModel::Model
  include ActiveRecord::AttributeAssignment

  attr_accessor :id, :ministry_id, :mcc, :period
  attr_reader :measurement,
              :total,
              :total_breakdown,
              :local,
              :local_breakdown,
              :self_breakdown,
              :my_measurements,
              :sub_ministries,
              :team,
              :self_assigned,
              :split_measurements

  delegate :perm_link_stub, to: :measurement

  def initialize(attributes = {})
    super(attributes)

    # default values
    @period ||= Time.zone.today.strftime('%Y-%m')
    @measurement = Measurement.find_by(total_id: id) if @id
  end

  def load
    raise if id.blank? || ministry_id.blank? || mcc.blank?

    @measurement ||= Measurement.find_by(total_id: id)
    load_total_from_gr
    load_local_from_gr
    load_user_from_gr
    load_sub_mins_from_gr
  end

  def load_measurements_of_type(type, dimension_level = nil, related_id = nil, period = nil)
    dimension_level ||= type
    resp = gr_singleton.find(measurement.send("#{type}_id"),
                             gr_request_params(dimension_level, related_id, period))
    resp['measurement_type']['measurements']
  end

  def load_total_from_gr
    gr_resp = load_measurements_of_type(:total)
    @total = build_monthly_hash(gr_resp)
  end

  def load_local_from_gr
    gr_resp = load_measurements_of_type(:local, :none)
    @local = build_monthly_hash(gr_resp)
    breakdown, this_period_sum = build_breakdown_hash(gr_resp)
    @local[period] = this_period_sum
    @local_breakdown = breakdown
  end

  def load_user_from_gr
    return unless Power.current.try(:assignment)
    gr_resp = load_measurements_of_type(:person, :none, Power.current.assignment.gr_id)
    @my_measurements = build_monthly_hash(gr_resp)
    breakdown, this_period_sum = build_breakdown_hash(gr_resp)
    if @my_measurements[period] != this_period_sum
      @my_measurements[period] = this_period_sum
      push_personal_to_gr(this_period_sum)
    end
    @self_breakdown = breakdown
  end

  def load_sub_mins_from_gr
    submin_data = load_measurements_of_type(:total, nil, ministry.children.collect(&:gr_id), period)
    @sub_ministries = ministry.children.map do |child_min|
      measurements_for_child = submin_data.select { |m| m['related_entity_id'] == child_min.gr_id }
      {
        name: child_min.name,
        ministry_id: child_min.gr_id,
        total: measurements_for_child.sum { |m| m['value'].to_f }
      }
    end
  end

  private

  def build_monthly_hash(gr_resp)
    monthly_hash = {}
    i_period = period_from
    gr_resp = gr_resp.select { |m| m['dimension'] == @mcc }
    loop do
      monthly_hash[i_period] = gr_resp.find { |m| m['period'] == i_period }.try(:[], 'value').to_f
      break if i_period == period
      i_period = (Date.parse("#{i_period}-01") + 1.month).strftime('%Y-%m')
    end
    monthly_hash
  end

  def build_breakdown_hash(gr_resp)
    measurements = gr_resp.select { |m| m['period'] == @period && m['dimension'].start_with?("#{@mcc}_") }
    this_period_sum = measurements.sum { |m| m['value'].to_f }
    breakdown = measurements.group_by { |m| m['dimension'].sub("#{@mcc}_", '') }
    breakdown = breakdown.each_with_object({}) do |args, hash|
      dimension = args[0]
      group = args[1]
      hash[dimension] = group.sum { |m| m['value'].to_f }
    end
    breakdown['total'] = this_period_sum
    [breakdown, this_period_sum]
  end

  def push_personal_to_gr(new_value)
    push_measurement_to_gr(new_value, Power.current.assignment.gr_id, measurement.person_id)
  end

  def push_measurement_to_gr(value, related_id, type_id)
    measurement_body = {
      measurement: {
        period: period,
        value: value,
        related_entity_id: related_id,
        measurement_type_id: type_id
      }
    }
    GlobalRegistryClient.client(:measurement).post(measurement_body)
  end

  def gr_request_params(dimension_level, related_id = nil, period = nil)
    related_id ||= ministry_id
    period ||= period_from
    {
      'filters[related_entity_id][]': related_id,
      'filters[period_from]': period,
      'filters[period_to]': period,
      'filters[dimension]': dimension_filter(dimension_level),
      per_page: 250
    }
  end

  def period_from
    return @period_from if @period_from
    from = Date.parse("#{period}-01") - 5.months
    @period_from = from.strftime('%Y-%m')
  end

  def dimension_filter(level)
    if level == :total
      mcc
    elsif level != :none
      "#{mcc}_#{source}"
    end
  end

  def ministry
    @ministry ||= Ministry.find_by(gr_id: ministry_id)
  end

  def gr_singleton
    GlobalRegistryClient.client(:measurement_type)
  end
end
