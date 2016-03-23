# frozen_string_literal: true
class MeasurementListReader
  include ActiveModel::Model
  include ActiveRecord::AttributeAssignment

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

  def load_measurements_from_gr
    work_q = Queue.new
    params = gr_loading_params
    @measurements.each { |m| work_q.push m }
    workers = (1..ENV['MEASUREMENT_THREAD_COUNT'].to_i).map do
      Thread.new do
        until work_q.empty?
          measurement = work_q.pop(true)
          Measurement::GrValueLoader.new(params.merge(measurement: measurement)).load_gr_value
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
    query = []
    query = [show_filter] if ministry.lmi_show.present?
    query << hide_filter if ministry.lmi_hide.present?
    if query.count == 2
      @measurements.where(query[0].or(query[1]))
    elsif query.count == 1
      @measurements.where(query[0])
    else
      @measurements
    end
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
    table[:perm_link].does_not_match('%_custom_%').and(table[:perm_link].not_in(perm_links))
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
end
