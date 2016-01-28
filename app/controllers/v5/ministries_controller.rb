module V5
  class MinistriesController < V5::BaseController
    include V5::AccessTokenProtectedConcern

    before_action :authenticate_request

    def index
      if params.key?(:refresh) && params[:refresh] == 'true'
        GlobalRegistry::SyncMinistriesWorker.perform_async
        render status: :accepted, plain: 'Accepted'
        return
      end

      ministries = Ministry.all
      # Render only publicly accessible properties
      render json: ministries, each_serializer: MinistryPublicSerializer
    end

    def show
      ministry = Ministry.find_by(ministry_id: params[:id])
      api_error 'Missing or Invalid Ministry ID (\'ministry_id\' parameter).' and return if ministry.nil?

      # TODO: Check permissions for ministry
      render json: ministry
    end

    def create
    end

    def update
    end
  end
end
