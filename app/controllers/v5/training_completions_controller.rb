# frozen_string_literal: true
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
      head 204
    end

    private

    def request_power
      training = if params[:action] == 'update' || params[:action] == 'destroy'
                   TrainingCompletion.find_by(id: params[:id]).try(:training)
                 else
                   Training.find_by(id: params[:training_id])
                 end
      Power.new(current_user, training.try(:ministry))
    end

    def load_training_completion
      @completion ||= training_completion_scope.find(params[:id])
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
             status: save_status_code
    end

    def render_errors
      render json: @completion.errors.messages, status: :bad_request
    end

    def training_params
      params.permit([:training_id, :phase, :number_completed, :date])
    end
  end
end
