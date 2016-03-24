# frozen_string_literal: true
class Measurement
  class GrValueLoader
    NUMBER_OF_HISTORIC_MONTHS = 11

    include ActiveModel::Model

    attr_accessor :gr_client, :measurement, :levels, :ministry_id, :assignment_id,
                  :mcc, :period, :source, :historical

    def load_gr_value
      return load_historic_gr_values if @historical
      @levels.each do |level|
        measurement_level_id = @measurement.send("#{level}_id")
        filter_params = gr_request_params(level)
        gr_resp = @gr_client.find(measurement_level_id, filter_params)
        value = gr_resp['measurement_type']['measurements'].sum { |m| m['value'].to_f }
        @measurement.send("#{level}=", value)
      end
    end

    private

    def load_historic_gr_values
      return unless can_historic
      gr_resp = GlobalRegistry::MeasurementType
                .find(@measurement.total_id, gr_request_params(:total))['measurement_type']['measurements']
      @measurement.total = build_total_hash(gr_resp)
    end

    def build_total_hash(gr_resp)
      (0..NUMBER_OF_HISTORIC_MONTHS).each_with_object({}) do |i, hash|
        month_period = (Date.parse("#{@period}-01") - i.months).strftime('%Y-%m')
        hash[month_period] = gr_resp.find { |m| m['period'] == month_period }.try(:[], 'value').to_f
      end
    end

    def gr_request_params(level)
      related_id = if level == :person
                     @assignment_id
                   else
                     @ministry_id
                   end
      {
        'filters[related_entity_id]': related_id,
        'filters[period_from]': period_from,
        'filters[period_to]': @period,
        'filters[dimension]': dimension_filter(level),
        per_page: 250
      }
    end

    def period_from
      return @period unless @historical && can_historic
      from = Date.parse("#{@period}-01") - NUMBER_OF_HISTORIC_MONTHS.months
      from.strftime('%Y-%m')
    end

    def can_historic
      Power.current.blank? || Power.current.historic_measurements
    end

    def dimension_filter(level)
      if level == :total
        @mcc
      else
        "#{@mcc}_#{@source}"
      end
    end
  end
end
