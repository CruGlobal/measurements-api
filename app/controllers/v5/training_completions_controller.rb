module V5
  class TrainingCompletionsController < V5::BaseUserController
    power :training_completions, as: :training_completion_scope

    def create
      build_training_completion
      save_training_completion or render_errors
    end

    def update
      load_training_completion
      create
    end

    def destroy
      load_training_completion
      @completion.destroy
      render nothing: true, status: 201
    end

    private

    def request_power
      ministry = Training.find_by(id: params[:training_id]).try(:ministry)
      Power.new(current_user, ministry)
    end

    def load_training_completion
      @completion ||= training_completion_scope.find_by(id: params[:id])
    end

    def build_training_completion
      @completion ||= training_completion_scope.find_by(training_id: params[:training_id], phase: params[:phase])
      @completion ||= TrainingCompletion.new
      @completion.attributes = training_params
    end

    def save_training_completion
      return unless @completion.save
      render json: @completion,
             serializer: V5::TrainingCompletionSerializer,
             status: 201
    end

    def render_errors
      render json: @completion.errors.messages, status: :bad_request
    end

    def training_params
      params.permit([:training_id, :phase, :number_completed, :date])
    end
  end
end
