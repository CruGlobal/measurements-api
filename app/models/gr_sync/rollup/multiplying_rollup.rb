# frozen_string_literal: true

module GrSync
  module Rollup
    class MultiplyingRollup < ::GrSync::MeasurementRollup
      LMI = "lmi_total_send_mult_disc"

      def gr_measurement_type_filters
        super.merge("filters[dimension]" => "gcm_churches")
      end

      def stats_for_period(period)
        stats = stats_for_churches_missing_values(period)
        stats.merge(stats_for_churches_with_values(period)) do |_key, oldval, newval|
          (newval.to_i + oldval.to_i).to_s
        end
      end

      private

      # Number of active churches with development > 'target', that do not have church_values,
      # grouped by ministry in the given period
      def stats_for_churches_missing_values(period) # rubocop:disable Metrics/AbcSize
        church = ::Church.arel_table
        values = ::ChurchValue.arel_table

        query = base_query(period)
          .join(values, ::Arel::Nodes::OuterJoin)
          .on(values[:church_id].eq(church[:id])
                        .and(values[:period].lteq(period.strftime(PERIOD_FORMAT))))
          .where(church[:development].gt(::Church.developments[:target]))
          .where(values[:id].eq(nil))
        execute(query.to_sql).rows.to_h
      end

      # Number of active churches with church_values.development > 'target' in the given period
      # grouped by ministry
      def stats_for_churches_with_values(period) # rubocop:disable Metrics/AbcSize
        church = ::Church.arel_table
        values = ::ChurchValue.arel_table

        subquery = values.project(values[:church_id], values[:period].maximum)
          .where(values[:period].lteq(period.strftime(PERIOD_FORMAT)))
          .group(values[:church_id])

        query = base_query(period)
          .join(values).on(values[:church_id].eq(church[:id]))
          .where(values[:development].gt(::Church.developments[:target]))
          .where(::Arel.sql("(church_id, period)").in(::Arel.sql("(#{subquery.to_sql})")))
        execute(query.to_sql).rows.to_h
      end

      def base_query(period) # rubocop:disable Metrics/AbcSize
        church = ::Church.arel_table
        ministry = ::Ministry.arel_table

        church.project(ministry[:gr_id], church[:id].count)
          .join(ministry).on(ministry[:id].eq(church[:ministry_id]))
          .where(church[:ministry_id].not_eq(nil))
          .where(church[:start_date].lteq(period.end_of_month))
          .where(church[:end_date].eq(nil).or(church[:end_date].gteq(period.months_since(1).beginning_of_month)))
          .group(ministry[:gr_id])
      end
    end
  end
end
