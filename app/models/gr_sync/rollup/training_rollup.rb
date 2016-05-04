# frozen_string_literal: true
module GrSync
  module Rollup
    class TrainingRollup < ::GrSync::MeasurementRollup
      LMI = 'lmi_total_send_train'

      def gr_measurement_type_filters
        super.merge('filters[dimension:like]' => '_training')
      end

      def stats_for_period(period) # rubocop:disable Metrics/AbcSize
        ministry = ::Ministry.arel_table
        training = ::Training.arel_table
        complete = ::TrainingCompletion.arel_table

        query = complete.project(ministry[:gr_id], training[:mcc], complete[:number_completed].sum)
                        .join(training).on(training[:id].eq(complete[:training_id]))
                        .join(ministry).on(ministry[:id].eq(training[:ministry_id]))
                        .where(training[:ministry_id].not_eq(nil))
                        .where(training[:mcc].not_eq(nil))
                        .where(training[:date].lteq(period.end_of_month))
                        .where(training[:date].gteq(period.beginning_of_month))
                        .group(ministry[:gr_id], training[:mcc])
        execute(query.to_sql).to_hash
      end

      def measurements_for_period(period)
        measurements = []
        stats_for_period(period).each do |row|
          dimension = "#{row['mcc']}_training"
          value = row['sum'].to_f
          if value != gr_current_value(row['gr_id'], period, dimension)
            measurements << { period: period.strftime(PERIOD_FORMAT), related_entity_id: row['gr_id'],
                              mcc: dimension, value: value.to_s, measurement_type_id: gr_measurement_type['id'] }
          end
        end
        measurements
      end

      def gr_current_value(related_entity_id, period, dimension)
        period_str = period.strftime(PERIOD_FORMAT)
        found = gr_measurement_type['measurements'].find do |item|
          item['period'] == period_str &&
            item['related_entity_id'] == related_entity_id &&
            item['dimension'] == dimension
        end
        found['value'].to_f unless found.nil?
      end
    end
  end
end
