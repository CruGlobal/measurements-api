module V5
  class MeasurementsController < V5::BaseUserController
    def index
      load_measurements
      render json: @measurements, each_serializer: V5::MeasurementSerializer
    end

    def show
    end

    def create
    end

    private

    def load_measurements
      @measurements ||= MeasurementList
                        .new(params.permit(:ministry_id, :mcc, :period, :source, :historical))
                        .load
    end
  end
end
