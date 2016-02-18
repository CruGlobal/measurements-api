module V5
  class MinistriesController < V5::BaseUserController
    power :ministries, map: {
      [:index] => :ministries,
      [:show] => :show_ministry,
      [:create] => :create_ministry,
      [:update] => :update_ministry
    }, as: :ministry_scope

    def index
      return if refresh_ministries
      load_ministries
      render_ministries
    end

    def show
      load_ministry
      render_ministry
    end

    def create
      if build_ministry
        render_ministry :created
      else
        render_errors
      end
    end

    def update
      load_ministry
      if build_ministry
        render_ministry
      else
        render_errors
      end
    end

    private

    def load_ministries
      @ministries ||= ministry_scope
    end

    def load_ministry
      @ministry ||= ministry_scope
    end

    def build_ministry
      @ministry ||= ministry_scope.new
      @ministry.attributes = ministry_params
      @ministry.save
    end

    def refresh_ministries
      if params.key?(:refresh) && params[:refresh] == 'true'
        GlobalRegistry::SyncMinistriesWorker.perform_async
        render status: :accepted, plain: 'Accepted'
        return true
      end
      false
    end

    def render_ministries
      render json: @ministries, each_serializer: MinistryPublicSerializer
    end

    def render_ministry(status = nil)
      status ||= :ok
      render json: @ministry, status: status, serializer: ::MinistrySerializer if @ministry
    end

    def ministry_params
      valid_params = %i(name parent_id min_code lmi_show lmi_hide mccs
                        default_mcc hide_reports_tab location location_zoom)
      post_params.permit valid_params
    end

    protected

    def request_power
      ministry_id = case params[:action].to_sym
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

    def render_consul_powerless(exception)
      message = case params[:action].to_sym
                when :show
                  'Missing or Invalid Ministry ID (\'ministry_id\' parameter).'
                else
                  exception.message
                end
      api_error message
    end
  end
end
