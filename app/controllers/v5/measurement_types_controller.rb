module V5
  class MeasurementTypesController < V5::BaseUserController
    def index
      render json: MeasurementType.all_localized_with(ministry_id: ministry.try(:id),
                                                      locale: params[:locale] || 'en'),
             each_serializer: V5::MeasurementTypeSerializer
    end

    def show
      render json: load_measurement_type,
             serializer: V5::MeasurementTypeSerializer
    end

    def create
      build_measurement_type
      save_measurement_type or render_errors
    end

    def update
      load_measurement_type
      create
    end

    private

    def load_measurement_type
      return @measurement_type if @measurement_type
      measurement = Measurement.find_by(total_id: params[:id])
      measurement ||= Measurement.find_by_perm_link(params[:id])
      @measurement_type = MeasurementType.new(measurement: measurement, ministry_id: ministry.try(:id),
                                              locale: params[:locale] || 'en')
    end

    def build_measurement_type
      @measurement_type ||= MeasurementType::UserCreatedMeasurementType.new
      @measurement_type.attributes = measurement_type_params
    end

    def save_measurement_type
      new_record = @measurement_type.new_record?
      return unless @measurement_type.save
      render json: @measurement_type,
             serializer: V5::MeasurementTypeSerializer,
             status: save_status_code(new_record)
    end

    def ministry
      return @ministry if @ministry || params[:ministry_id].blank?
      @ministry = Ministry.find_by(gr_id: params[:ministry_id])
      params[:ministry_id] = nil unless @ministry
      @ministry
    end

    def render_errors
      render json: @measurement_type.errors.messages, status: :bad_request
    end

    def measurement_type_params
      permitted = params.permit([:english, :perm_link_stub, :description, :section, :column,
                                 :sort_order, :parent_id, :localized_name, :localized_description,
                                 :ministry_id, :locale])
      permitted[:ministry_id] = ministry.id if params[:ministry_id]
      permitted
    end
  end
end
