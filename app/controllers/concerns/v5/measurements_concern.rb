module V5
  module MeasurementsConcern
    extend ActiveSupport::Concern

    as_trait do |authorize:|
      if authorize
        power :measurements, map: {show: :showing_measurement}
      end
    end

    def index
      load_measurements
      render json: @measurements, scope: {locale: params[:locale], ministry: ministry},
             each_serializer: V5::MeasurementSerializer
    end

    def show
      load_measurement
      render json: @measurement, serializer: V5::MeasurementDetailsSerializer
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    def create
      list = MeasurementListUpdater.new(params.permit!.to_h["_json"])
      if list.commit
        head :created
      else
        render_error list.error
      end
    end

    protected

    def load_measurements
      @measurements ||= MeasurementListReader
        .new(params.permit(:ministry_id, :mcc, :period, :source, :historical))
        .load
    end

    def load_measurement
      return @measurement if @measurement
      @measurement = MeasurementDetails.new(params.permit(:id, :ministry_id, :mcc, :period).to_h)
      @measurement.load
    end

    def ministry
      @ministry ||= Ministry.ministry(params[:ministry_id])
    end
  end
end
