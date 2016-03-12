class MeasurementDetails < ActiveModelSerializers::Model
  include ActiveRecord::AttributeAssignment

  attr_accessor :id, :ministry_id, :mcc, :period
  attr_reader :measurement, :total, :local, :local_breakdown, :self_breakdown, :my_measurements,
              :sub_ministries, :team, :self_assigned, :split_measurements

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
    load_team_from_gr
    load_split_measurements

    update_total_in_gr
  end

  def load_total_from_gr
    gr_resp = load_measurements_of_type(:total, :total)
    @total = build_monthly_hash(gr_resp)
  end

  def load_local_from_gr
    gr_resp = load_measurements_of_type(:local, :none)
    @local = build_monthly_hash(gr_resp)
    @local_breakdown, this_period_sum = build_breakdown_hash(gr_resp)
    @local[period] = this_period_sum
  end

  def load_user_from_gr
    return unless Power.current.try(:assignment)
    gr_resp = load_measurements_of_type(:person, :none, Power.current.assignment.gr_id)
    @my_measurements = build_monthly_hash(gr_resp)
    @self_breakdown, this_period_sum = build_breakdown_hash(gr_resp)
    if @my_measurements[period] != this_period_sum
      @my_measurements[period] = this_period_sum
      update_personal_in_gr(this_period_sum)
    end
  end

  def load_sub_mins_from_gr
    submin_data = load_measurements_of_type(:total, :total, ministry.children.collect(&:gr_id), period)
    @sub_ministries = ministry.children.map do |child_min|
      measurements_for_child = submin_data.select { |m| m['related_entity_id'] == child_min.gr_id }
      {
        name: child_min.name,
        ministry_id: child_min.gr_id,
        total: measurements_for_child.sum { |m| m['value'].to_f }
      }
    end
  end

  def load_team_from_gr
    self_assigned, approved_people = load_assignments

    assignment_ids = (self_assigned + approved_people).collect(&:gr_id)

    if assignment_ids.any?
      params = gr_request_params(:none, assignment_ids, period).merge('filters[dimension:like]': "#{mcc}_")
      team_data = get_from_gr_with_params(:person, params)
    end

    @self_assigned = self_assigned.map do |assignment|
      team_member_hash(assignment, team_data)
    end
    @team = approved_people.map do |assignment|
      team_member_hash(assignment, team_data)
    end
  end

  def load_split_measurements
    return if measurement.children.none?
    @split_measurements = measurement.children.each_with_object({}) do |child, hash|
      params = gr_request_params(:total, nil, period)
      resp = gr_singleton.find(child.total_id, params)['measurement_type']['measurements']
      hash[child.perm_link_stub] = resp.first['value'].to_i if resp.any?
    end
  end

  def update_total_in_gr
    new_total = count_total
    return if @total[period] == new_total
    @total[period] = new_total
    push_measurement_to_gr(new_total, ministry.gr_id, measurement.total_id)
  end

  private

  def load_assignments
    [ministry.assignments.includes(:person).where(role: :self_assigned).to_a,
     ministry.assignments.includes(:person).where(Assignment.approved_condition).to_a]
  end

  def load_measurements_of_type(type, dimension_level = nil, related_id = nil, period = nil)
    get_from_gr_with_params(type, gr_request_params(dimension_level, related_id, period))
  end

  def get_from_gr_with_params(type, params)
    gr_singleton.find(measurement.send("#{type}_id"), params)['measurement_type']['measurements']
  end

  def gr_request_params(dimension_level, related_id = nil, period = nil)
    {
      'filters[related_entity_id][]': related_id || ministry_id,
      'filters[period_from]': period || period_from,
      'filters[period_to]': period,
      'filters[dimension]': dimension_filter(dimension_level),
      per_page: 250
    }
  end

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

  def team_member_hash(assignment, gr_data)
    total = gr_data.find { |m| m['related_entity_id'] == assignment.gr_id }.try(:[], 'value').to_f
    {
      assignment_id: assignment.gr_id,
      team_role: assignment.role,
      first_name: assignment.person.first_name,
      last_name: assignment.person.last_name,
      person_id: assignment.person.gr_id,
      total: total
    }
  end

  def update_personal_in_gr(new_value)
    push_measurement_to_gr(new_value, Power.current.assignment.gr_id, measurement.person_id)
  end

  def push_measurement_to_gr(value, related_id, type_id)
    GlobalRegistryClient.client(:measurement).post(measurement: {
                                                     period: period,
                                                     value: value,
                                                     related_entity_id: related_id,
                                                     measurement_type_id: type_id
                                                   })
  end

  def count_total
    new_total = @local[period] + @sub_ministries.sum { |sub| sub[:total] } + @team.sum { |sub| sub[:total] }
    new_total += @my_measurements[period] if @my_measurements
    new_total += @split_measurements.sum { |_k, v| v.to_i } if @split_measurements
    new_total
  end

  def period_from
    @period_from ||= (Date.parse("#{period}-01") - 5.months).strftime('%Y-%m')
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
