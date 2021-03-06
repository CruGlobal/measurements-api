module V5
  module MinistriesConcern
    extend ActiveSupport::Concern

    as_trait do |authorize:|
      if authorize
        power :ministries, map: {
          [:show] => :show_ministry,
          [:update] => :update_ministry,
          [:create] => :create_ministry,
        }, as: :ministry_scope
      end
    end

    def index
      # Disable Manual ministry refresh
      # return if refresh_ministries
      load_ministries
      render_ministries
    end

    def show
      load_ministry || render_not_found
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
      load_ministry || render_not_found && return
      if build_ministry
        render_ministry
      else
        render_errors
      end
    end

    protected

    def load_ministries
      @ministries ||= ministry_scope
      # Filter ministries if whq_only
      if bool_value(params[:whq_only])
        @ministries = @ministries.where(ministry_scope: ::Ministry::SCOPES).includes(:area).order(name: :asc)
      end
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
      if params.key?(:refresh) && params[:refresh] == "true"
        # Always sync the ministries using the root global registry key so that
        # a the /v5/sys_ministries endpoint wiht a refresh won't make our logal
        # ministries list be different.
        GrSync::WithGrWorker.queue_call_with_root(GrSync::MinistriesSync, :sync_all)
        render status: :accepted, plain: "Accepted"
        return true
      end
      false
    end

    def render_ministries
      if bool_value(params[:whq_only])
        render json: @ministries, each_serializer: WhqMinistrySerializer
      else
        render json: @ministries, each_serializer: MinistryPublicSerializer
      end
    end

    def render_ministry(status = nil)
      status ||= :ok
      render json: @ministry, status: status, serializer: MinistrySerializer if @ministry
    end

    def render_errors
      render json: @ministry.errors.messages, status: :bad_request
    end

    def ministry_params
      permitted_params = post_params.permit(*::Ministry::PERMITTED_PARAMS)
      # Set nil array fields to an empty array (http://guides.rubyonrails.org/security.html#unsafe-query-generation)
      %i[lmi_show lmi_hide mccs].each do |param|
        if permitted_params.to_h.key(param)
          permitted_params[param] = [] if permitted_params[param].nil?
        end
      end
      if permitted_params.key? :parent_id
        permitted_params[:parent_id] =
          Ministry.ministry(permitted_params[:parent_id]).try(:id)
      end
      permitted_params
    end

    # convert stings like '1' to booleans
    def bool_value(value)
      value = @filters[value] if value.is_a? Symbol
      ActiveRecord::Type::Boolean.new.cast(value)
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
        api_error "INSUFFICIENT_RIGHTS - You must be a member of one of the following roles: " \
         "#{Assignment::LEADER_ROLES.join(", ")}.", status: :unauthorized
      else
        super
      end
    end
  end
end
