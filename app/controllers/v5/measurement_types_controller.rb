module V5
  class MeasurementTypesController < V5::BaseUserController
    def index
      render json: Measurement.all,
             each_serializer: V5::MeasurementTypeSerializer,
             scope: { ministry_id: ministry.id, locale: params[:locale] }
    end

    def show
      render json: load_measurement,
             serializer: V5::MeasurementTypeSerializer,
             scope: { ministry_id: ministry.id, locale: params[:locale] }
    end

    def create
    end

    def update
    end

    private

    def load_measurement
      @measurement ||= Measurement.find_by(total_id: params[:id])
      @measurement ||= Measurement.find_by_perm_link(params[:id])
    end

    def ministry
      Ministry.find_by(gr_id: params[:ministry_id])
    end
  end
end
