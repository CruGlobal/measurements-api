# frozen_string_literal: true
class Measurement
  class MeasurementRollup
    def run(measurement, ministry_gr_id, period, mcc, gr_client = nil)
      @measurement = measurement
      @ministry_gr_id = ministry_gr_id
      @period = period
      @mcc = mcc

      @gr_client = gr_client.present? ? gr_client.measurement_type : GlobalRegistry::MeasurementType.new
      @ministry = Ministry.ministry(ministry_gr_id)
      @running_total = 0

      process_local_measurements
      process_sub_min_measurements
      process_team_measurements
      process_split_measurements
      process_total_measurements

      recurse_up
    end

    private

    def process_local_measurements
      local_measurement_params = { 'filters[dimension:like]': "#{@mcc}_" }
      process_measurement_level(@measurement.local_id, @ministry_gr_id, local_measurement_params)
    end

    def process_sub_min_measurements
      sub_min_gr_ids = @ministry.children.pluck(:gr_id)
      return if @measurement.parent_id.present? || sub_min_gr_ids.none?
      process_measurement_level(@measurement.total_id, sub_min_gr_ids, mcc_filter)
    end

    def process_team_measurements
      team_members = @ministry.assignments.local_approved.pluck(:gr_id)
      team_measurement_params = { 'filters[dimension:like]': "#{@mcc}_" }
      process_measurement_level(@measurement.person_id, team_members, team_measurement_params)
    end

    def process_split_measurements
      @measurement.children.each do |split_meas|
        child_value = load_measurements(split_meas.total_id, @ministry_gr_id, @period, mcc_filter).dig(0, :value)
        @running_total += child_value.to_f
      end
    end

    def process_total_measurements
      total_measurements = load_measurements(@measurement.total_id, @ministry_gr_id, @period, mcc_filter)
      total_in_gr = total_measurements.find { |m| m['dimension'] == @mcc }.try(:[], 'value')
      if total_in_gr != @running_total
        push_measurement_to_gr(@running_total, @ministry_gr_id, @measurement.total_id)
      end
    end

    # process methods up there ☝

    def process_measurement_level(measurement_type_id, related_ids, params)
      totals = load_measurements(measurement_type_id, related_ids, @period, params)
      @running_total += totals.sum { |m| m['value'].to_f }
    end

    def recurse_up
      self.class.new.run(@measurement.parent, @ministry_gr_id, @period, @mcc) if @measurement.parent
    end

    def load_measurements(measurement_id, related_id = nil, period = nil, params = nil)
      request_params = {
        'filters[related_entity_id][]': related_id,
        'filters[period_from]': period,
        'filters[period_to]': period,
        per_page: 250
      }
      request_params = request_params.merge(params) if params

      @gr_client.find(measurement_id, request_params)['measurement_type']['measurements']
    end

    def push_measurement_to_gr(value, related_id, type_id)
      GlobalRegistry::Measurement.new.post(measurement: {
                                             period: @period,
                                             value: value,
                                             related_entity_id: related_id,
                                             measurement_type_id: type_id,
                                             dimension: @mcc
                                           })
    end

    def mcc_filter
      { 'filters[dimension]': @mcc }
    end
  end
end
