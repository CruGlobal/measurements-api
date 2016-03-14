module V5
  class MeasurementsController < V5::BaseUserController
    power :measurements, map: { show: :showing_measurement }

    def index
      load_measurements
      render json: @measurements, each_serializer: V5::MeasurementSerializer
    end

    def show
      load_measurement
      render json: @measurement, serializer: V5::MeasurementDetailsSerializer
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    def create
      # read json as params['_json']
      render nothing: true, status: :created
    end

    private

    def load_measurements
      @measurements ||= MeasurementListReader
                        .new(params.permit(:ministry_id, :mcc, :period, :source, :historical))
                        .load
    end

    def load_measurement
      return @measurement if @measurement
      @measurement = MeasurementDetails.new(params.permit(:id, :ministry_id, :mcc, :period))
      @measurement.load
    end
  end
end
