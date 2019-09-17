# frozen_string_literal: true

module GrSync
  class MeasurementRollup
    PERIOD_FORMAT = "%Y-%m"

    attr_reader :gr_client

    def initialize(gr_client)
      @gr_client ||= gr_client
    end

    def rollup
      measurements = []
      (0..months).each do |increment|
        period = today.months_ago(increment)
        measurements.concat(measurements_for_period(period))
      end
      push_measurements(measurements)
    end

    protected

    def measurements_for_period(period)
      measurements = []
      stats_for_period(period).each do |entity_id, value|
        value = value.to_f
        if value != gr_current_value(entity_id, period)
          measurements << {period: period.strftime(PERIOD_FORMAT), related_entity_id: entity_id,
                           mcc: dimension, value: value.to_s, measurement_type_id: gr_measurement_type["id"],}
        end
      end
      measurements
    end

    def measurement
      @measurement ||= ::Measurement.find_by(perm_link: self.class::LMI)
    end

    def gr_measurement_type_filters
      {
        "filters[period_from]" => today.months_ago(months).strftime(PERIOD_FORMAT),
        "filters[period_to]" => today.strftime(PERIOD_FORMAT),
      }
    end

    def gr_measurement_type
      @gr_measurement_type ||=
        gr_client.measurement_type.find(measurement.local_id, gr_measurement_type_filters)["measurement_type"]
    end

    def gr_current_value(related_entity_id, period)
      period_str = period.strftime(PERIOD_FORMAT)
      found = gr_measurement_type["measurements"].find { |item|
        item["period"] == period_str && item["related_entity_id"] == related_entity_id
      }
      found["value"].to_f unless found.nil?
    end

    def push_measurements(measurements, batch_size = 100)
      return if measurements.empty?
      measurements.each_slice(batch_size) do |batch|
        ::MeasurementListUpdater.new(batch).commit
      end
    end

    def stats_for_period(_period)
      # Subclass Must Implement
      []
    end

    def dimension
      "gcm_churches"
    end

    def today
      @today ||= Time.zone.today
    end

    def months
      day_of_year = today.yday
      @months ||= if day_of_year % 24 == 1
        12
      elsif day_of_year % 6 == 1
        5
      elsif day_of_year % 3 == 1
        2
      else
        1
      end
    end

    def execute(sql)
      connection = ::ActiveRecord::Base.connection
      connection.exec_query(sql)
    end
  end
end
