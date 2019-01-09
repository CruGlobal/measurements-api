# frozen_string_literal: true
class MeasurementListReader
  include ActiveModel::Model

  attr_accessor :ministry_id, :mcc, :period, :source, :historical

  def initialize(attributes = {})
    super(attributes)

    # default values
    @period ||= Time.zone.today.strftime('%Y-%m')
    @source ||= 'gma-app'
  end

  def load
    raise if ministry_id.blank? || mcc.blank?

    @measurements = Measurement.where(mcc_filter: [nil, mcc])
    @measurements = filter_by_show_hide
    load_measurements_from_gr
    split_children
  end

  private

  def load_measurements_from_gr # rubocop:disable Metrics/MethodLength
    work_q = Queue.new
    params = gr_loading_params
    @measurements.each { |m| work_q.push m }
    workers = (1..thread_count).map do
      Thread.new do
        begin
          loop do
            Rails.application.reloader.wrap do
              Measurement::GrValueLoader.new(params.merge(measurement: work_q.pop(true))).load_gr_value
            end
          end
        rescue ThreadError => e
          # we don't care about thread errors because
          raise e unless e.message == 'queue empty'
        end
      end
    end
    workers.each(&:join)
  end

  def gr_loading_params
    {
      gr_client: GlobalRegistryClient.client(:measurement_type),
      levels: Power.current.try(:measurement_levels) || [:total, :local, :person],
      assignment_id: Power.current.try(:assignment).try(:gr_id),
      ministry_id: @ministry_id,
      mcc: @mcc,
      period: @period,
      source: @source,
      historical: @historical
    }
  end

  def filter_by_show_hide
    query = hide_filter
    query = query.or(show_filter) if ministry.lmi_show.present?
    @measurements.where(query)
  end

  def ministry
    Ministry.find_by(gr_id: ministry_id)
  end

  # show the custom measurements
  def show_filter
    perm_links = ministry.lmi_show.map { |lmi| "lmi_total_custom_#{lmi}" }
    table[:perm_link].in(perm_links)
  end

  # core measurements to hide
  def hide_filter
    perm_links = ministry.lmi_hide.map { |lmi| "lmi_total_#{lmi}" }
    query = table[:perm_link].does_not_match('%_custom_%')
    query = query.and(table[:perm_link].not_in(perm_links)) if perm_links.any?
    query
  end

  def table
    Measurement.arel_table
  end

  def split_children
    @measurements.select do |meas|
      # use select instead since we already have them loaded in memory
      children = @measurements.select { |child| child.parent_id == meas.id }
      meas.loaded_children = children
      next meas if meas.parent_id.blank?
    end
  end

  def thread_count
    ENV.fetch('MEASUREMENT_THREAD_COUNT').to_i
  end
end
