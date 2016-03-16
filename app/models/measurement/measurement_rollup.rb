class Measurement
  class MeasurementRollup
    def run(perm_link, ministry_gr_id, period, mcc, rollup_parent_min = true)
      @perm_link = perm_link
      @ministry_gr_id = ministry_gr_id
      @period = period
      @mcc = mcc

      @sbr_gr_client = GlobalRegistryClient.client(:measurement_type)
      @non_sbr_gr_client = GlobalRegistryClient.client(:measurement)
      @measurement = Measurement.find_by(perm_link: perm_link)
      @ministry = Ministry.ministry(ministry_gr_id)
      @running_total = 0

      process_local_measurements
      process_sub_min_measurements
      process_team_measurements
      process_split_measurements
      process_total_measurements

      recurse_up(rollup_parent_min)
    end

    private

    def process_local_measurements
      local_measurement_params = { 'filters[perm_link]': @perm_link.sub('lmi_total_', 'lmi_local_'),
                                   'filters[dimension:like]': @mcc }
      local_measurements = load_measurements(@ministry_gr_id, @period, local_measurement_params)
      return if local_measurements.blank?
      @running_total += local_measurements.first['measurements'].sum { |m| m['value'].to_f }
    end

    def process_sub_min_measurements
      sub_min_gr_ids = @ministry.children.pluck(:gr_id)
      return unless @measurement.parent_id.blank? && sub_min_gr_ids.any?
      submin_totals = load_measurements(sub_min_gr_ids, @period, mcc_filter.merge('filters[perm_link]': @perm_link))
      return if submin_totals.blank?
      @running_total += submin_totals.first['measurements'].sum { |m| m['value'].to_f }
    end

    def process_team_measurements
      team_members = @ministry.assignments.local_approved.pluck(:gr_id)
      team_measurement_params = { 'filters[perm_link]': @perm_link.sub('lmi_total_', 'lmi_'),
                                  'filters[dimension:like]': "#{@mcc}_" }
      team_totals = load_measurements(team_members, @period, team_measurement_params)
      return if team_totals.blank?
      @running_total += team_totals.first['measurements'].sum { |m| m['value'].to_f }
    end

    def process_split_measurements
      @measurement.children.each do |split_meas|
        child_value = load_measurements_of_type(split_meas.total_id, @ministry_gr_id, @period, @mcc).dig(0, :value)
        @running_total += child_value.to_f
      end
    end

    def process_total_measurements
      total_measurement_params = mcc_filter.merge('filters[perm_link]': @perm_link)
      total_measurements = load_measurements(@ministry_gr_id, @period, total_measurement_params)
      total_in_gr = total_measurements.first['measurements'].find { |m| m['dimension'] == @mcc }.try(:[], 'value')
      if total_in_gr != @running_total
        push_measurement_to_gr(@running_total, @ministry_gr_id, @measurement.total_id)
      end
    end

    # process methods up there ☝

    def recurse_up(parent)
      if parent && @ministry.parent_id.present?
        self.class.new.run(@perm_link, @ministry.parent.gr_id, @period, @mcc, false)
      end
      self.class.new.run(@measurement.parent.perm_link, @ministry_gr_id, @period, @mcc) if @measurement.parent
    end

    def load_measurements_of_type(type, related_id = nil, period = nil, dimension = nil)
      params = gr_request_params(related_id, period)
      params['filters[dimension]'] = dimension
      find_from_gr_with_params(type, params)
    end

    def load_measurements(related_id = nil, period = nil, params = nil)
      request_params = gr_request_params(related_id, period)
      request_params = request_params.merge(params) if params
      get_from_gr_with_params(request_params)
    end

    def find_from_gr_with_params(type_id, params)
      @sbr_gr_client.find(type_id, params)['measurement_type']['measurements']
    end

    def get_from_gr_with_params(params)
      @sbr_gr_client.get(params)['measurement_types']
    end

    def gr_request_params(related_id, period)
      {
        'filters[related_entity_id][]': related_id,
        'filters[period_from]': period,
        'filters[period_to]': period,
        per_page: 250
      }
    end

    def push_measurement_to_gr(value, related_id, type_id)
      @non_sbr_gr_client.post(measurement: {
                                period: @period,
                                value: value,
                                related_entity_id: related_id,
                                measurement_type_id: type_id
                              })
    end

    def mcc_filter
      return {} if @mcc.blank? || @mcc == 'all'
      { 'filters[dimension]': @mcc }
    end
  end
end
