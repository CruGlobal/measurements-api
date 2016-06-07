# frozen_string_literal: true
module GrSync
  class MeasurementPush
    attr_reader :gr_client

    def initialize(gr_client)
      @gr_client ||= gr_client
    end

    def push_to_gr(measurement)
      measurement.symbolize_keys!
      gr_params = measurement.slice(:period, :value, :related_entity_id, :measurement_type_id)
      gr_params[:dimension] = measurement[:mcc]
      gr_params[:dimension] += "_#{measurement[:source]}" if measurement[:source].present?

      gr_client.measurements.post(measurement: gr_params)
    end

    def update_totals(measurement)
      measurement.symbolize_keys!
      measurement[:measurement] = Measurement.find(measurement[:measurement_id])
      mcc = measurement[:mcc]
      mcc = mcc[0..mcc.index('_') - 1] if mcc.include?('_')

      related_id = measurement[:related_entity_id]
      if measurement[:measurement_type_id] == measurement[:measurement].person_id
        related_id = Assignment.find_by(gr_id: measurement[:related_entity_id]).ministry.gr_id
      end
      update_ministry(related_id, measurement[:period], measurement[:measurement], mcc)
    end

    private

    def update_ministry(ministry_gr_id, period, measurement, mcc)
      Measurement::MeasurementRollup.new.run(measurement, ministry_gr_id, period, mcc, gr_client)
    end
  end
end
