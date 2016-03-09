module V5
  class MinistriesController < V5::BaseUserController
    power :ministries, map: {
      [:show, :update] => :show_ministry,
      [:create] => :create_ministry
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
      @ministry.created_by = current_user if @ministry.respond_to? :created_by=
      @ministry.attributes = ministry_params
      @ministry.save
    end

    def refresh_ministries
      if params.key?(:refresh) && params[:refresh] == 'true'
        GlobalRegistry::SyncMinistriesWorker.perform_async(GlobalRegistryClient.parameters)
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

    def render_errors
      render json: @ministry.errors.messages, status: :bad_request
    end

    def ministry_params
      valid_params = %i(name parent_id min_code lmi_show lmi_hide mccs ministry_scope
                        default_mcc hide_reports_tab location location_zoom)
      permitted_params = post_params.permit valid_params
      permitted_params[:parent_id] =
        Ministry.ministry(permitted_params[:parent_id]).try(:id) if permitted_params.key? :parent_id
      permitted_params
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
      when :show, :update
        api_error 'INSUFFICIENT_RIGHTS - You must be a member of one of the following roles: ' \
         "#{Assignment::LEADER_ROLES.join(', ')}.", status: :unauthorized
      else
        super
      end
    end
  end
end
