# frozen_string_literal: true
module GrSync
  module Rollup
    class TrainingRollup < ::GrSync::MeasurementRollup
      LMI = 'lmi_total_send_train'

      def gr_measurement_type_filters
        super.merge('filters[dimension:like]' => '_training')
      end

      def stats_for_period(_period)
        # ministry = ::Ministry.arel_table
        # training = ::Training.arel_table
        # complete = ::TrainingCompletion.arel_table
        []
      end
    end
  end
end

# Dim training_count_obj = (
#   From c In d.gcm_trainings
#   Where c.gcm_training_completions.Where(
#     Function(b) b.date.Year = PeriodDate.Year And b.date.Month = PeriodDate.Month
#   ).Count > 0
#   Select c.gcm_training_completions.Where(
#     Function(b) b.date.Year = PeriodDate.Year And b.date.Month = PeriodDate.Month
#   ).Max(Function(a) a.number_completed)
# )
#
# Dim q = From c In d.gcm_training_completions
# Where c.date.Year = PeriodDate.Year
# And c.date.Month = PeriodDate.Month
# Group By c.gcm_training.ministry_id, c.gcm_training.mcc Into Count()
