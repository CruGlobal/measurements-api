module V5
  class MinistriesController < V5::BaseUserController
    power :ministries, map: {
      [:index] => :ministries,
      [:show] => :showable_ministries,
      [:create] => :creatable_ministries,
      [:update] => :updatable_ministries
    }, as: :ministry_scope

    def index
      if params.key?(:refresh) && params[:refresh] == 'true'
        GlobalRegistry::SyncMinistriesWorker.perform_async
        render status: :accepted, plain: 'Accepted' and return
      end

      load_ministries
      render_ministries
    end

    def show
      load_ministry
      render_ministry
      # api_error 'Missing or Invalid Ministry ID (\'ministry_id\' parameter).' and return if ministry.nil?
      #
      # # TODO: Check permissions for ministry
      # # TODO: add Team Members (assignments)
      # render json: ministry
    end

    def create
      build_ministry
      # ministry = Ministry.create(request.request_parameters.with_indifferent_access)
      # # TODO: Create ValidationError model and serializer
      # render json: ministry.errors.messages and return unless ministry.errors.empty?
      # # TODO: Add current user as Leader role
      # render json: ministry, status: :created
    end

    def update
      ministry = Ministry.ministry(params[:id])
      ministry.update(request.request_parameters.with_indifferent_access)
      render json: ministry.errors.messages and return unless ministry.errors.empty?
      render json: ministry, status: :ok
    end

    protected

    def request_power
      ministry_id = case params[:action]
                    when :index
                      nil
                    when :show, :update
                      params[:id]
                    when :post
                      params[:parent_id]
                    else
                      return super
                    end
      Power.new(current_user, ministry_id)
    end

    def render_consul_powerless
      api_error('Don\'t do that!')
    end

    private

    def load_ministries
      @ministries ||= ministry_scope
    end

    def load_ministry
      @ministry ||= ministry_scope
    end

    def build_ministry
      @ministry ||= ministry_scope
    end

    def render_ministries
      render json: @ministries, each_serializer: MinistryPublicSerializer
    end

    def render_ministry(status = nil)
      status ||= :ok
      render json: @ministry, status: status, serializer: V5::MinistrySerializer if @ministry
    end
  end
end
