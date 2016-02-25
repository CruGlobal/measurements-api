module V5
  class MeasurementTypesController < V5::BaseUserController
    def index
      render json: Measurement.all,
             each_serializer: V5::MeasurementTypeSerializer,
             scope: { ministry_id: ministry.id, locale: params[:locale] }
    end

    def show
    end

    def create
    end

    def update
    end

    private

    def ministry
      Ministry.find_by(gr_id: params[:ministry_id])
    end
  end
end
