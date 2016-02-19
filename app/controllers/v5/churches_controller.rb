module V5
  class ChurchesController < V5::BaseUserController
    power :churches, map: { [:create, :update] => :changeable_churches }, as: :church_scope

    def index
      render json: filtered_churches,
             serializer_context_class: V5::ChurchArraySerializer,
             scope: { period: params[:period] }
    end

    def create
      build_church
      save_church or render_errors
    end

    def update
      load_church
      create
    end

    private

    def request_power
      ministry_id = if params[:action] == 'update'
                      Church.find_by(id: params[:id]).try(:ministry).try(:gr_id)
                    else
                      params[:ministry_id]
                    end
      Power.new(current_user, ministry_id)
    end

    def load_church
      @church ||= church_scope.find(params[:id])
    end

    def build_church
      @church ||= ::Church::UserCreatedChurch.new
      @church.attributes = church_params
    end

    def save_church
      render json: @church, status: 201 if @church.save
    end

    def render_errors
      render json: @church.errors.messages, status: :bad_request
    end

    def church_params
      permitted_params = [:name, :ministry_id, :contact_name, :contact_email, :contact_mobile,
                          :latitude, :longitude, :start_date, :jf_contrib, :parent_id, :development,
                          :size, :security]
      permitted_params = params.permit(permitted_params)
      permitted_params[:created_by_id] = current_user.id
      fix_enum_params(permitted_params, :security, :development)
    end

    def filtered_churches
      params[:period] ||= Time.zone.today.strftime('%Y-%m')
      churches = ::ChurchFilter.new(params).filter(church_scope)
      return churches unless params[:long_min]
      ::ChurchClusterer.new(params).cluster(churches)
    end
  end
end
