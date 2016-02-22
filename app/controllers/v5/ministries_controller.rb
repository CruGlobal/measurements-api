module V5
  class MinistriesController < V5::BaseUserController
    power :ministries, map: {
      [:show, :update] => :show_ministry,
      [:create] => :create_ministry
    }

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
      @ministries ||= current_power.ministries
    end

    def load_ministry
      @ministry ||= current_power.show_ministry
    end

    def build_ministry
      @ministry ||= current_power.create_ministry.new
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
      render json: @ministry, status: status, serializer: MinistrySerializer if @ministry
    end

    def ministry_params
      valid_params = %i(name parent_id min_code lmi_show lmi_hide mccs ministry_scope
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
      case params[:action].to_sym
      when :show
        api_error 'INSUFFICIENT_RIGHTS - You must be a member of one of the following roles:' \
         "#{Assignment::LEADER_ROLES.join(', ')}.", status: :unauthorized
      else
        super
      end
    end
  end
end
