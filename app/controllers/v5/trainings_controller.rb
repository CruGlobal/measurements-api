module V5
  class TrainingsController < V5::BaseUserController
    power :trainings, map: { [:create, :update] => :changeable_trainings }, as: :training_scope

    def index
      render json: filtered_trainings,
             each_serializer: V5::TrainingSerializer,
             scope: { period: params[:period] }
    end

    def create
      build_training
      save_training or render_errors
    end

    def update
      load_training
      create
    end

    private

    def request_power
      ministry_id = if params[:action] == 'update'
                      Training.find_by(id: params[:id]).try(:ministry).try(:gr_id)
                    else
                      params[:ministry_id]
                    end
      Power.new(current_user, ministry_id)
    end

    def load_training
      @training ||= training_scope.find(params[:id])
    end

    def build_training
      @training ||= ::Training::UserCreatedTraining.new
      @training.attributes = training_params
    end

    def save_training
      render json: @training, status: 201 if @training.save
    end

    def render_errors
      render json: @training.errors.messages, status: :bad_request
    end

    def training_params
      permitted_params = []
      permitted_params = params.permit(permitted_params)
      permitted_params[:created_by_id] = current_user.id
      permitted_params[:ministry_id] = Ministry.find_by(gr_id: permitted_params[:ministry_id]).try(:id)
      permitted_params
    end

    def filtered_trainings
      ::TrainingFilter.new(params).filter(training_scope)
    end
  end
end
