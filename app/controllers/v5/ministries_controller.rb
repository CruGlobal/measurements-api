module V5
  class MinistriesController < V5::BaseUserController
    def index
      if params.key?(:refresh) && params[:refresh] == 'true'
        GlobalRegistry::SyncMinistriesWorker.perform_async
        render status: :accepted, plain: 'Accepted' and return
      end

      ministries = Ministry.all
      # Render only publicly accessible properties
      render json: ministries, each_serializer: MinistryPublicSerializer
    end

    def show
      ministry = Ministry.ministry(params[:id])
      api_error 'Missing or Invalid Ministry ID (\'ministry_id\' parameter).' and return if ministry.nil?

      # TODO: Check permissions for ministry
      # TODO: add Team Members (assignments)
      render json: ministry
    end

    def create
      ministry = Ministry.create(request.request_parameters.with_indifferent_access)
      # TODO: Create ValidationError model and serializer
      render json: ministry.errors.messages and return unless ministry.errors.empty?
      # TODO: Add current user as Leader role
      render json: ministry, status: :created
    end

    def update
      ministry = Ministry.ministry(params[:id])
      ministry.update(request.request_parameters.with_indifferent_access)
      render json: ministry.errors.messages and return unless ministry.errors.empty?
      render json: ministry, status: :ok
    end
  end
end
