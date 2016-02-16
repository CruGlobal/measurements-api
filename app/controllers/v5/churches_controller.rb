module V5
  class ChurchesController < V5::BaseController
    include V5::AccessTokenProtectedConcern

    before_action :authenticate_request

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

    def load_church
      @church ||= church_scope.find(params[:id])
    end

    def build_church
      @church ||= church_scope.build
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
      params.permit(permitted_params)
    end

    def church_scope
      Church.all
    end

    def filtered_churches
      params[:period] ||= Time.zone.today.strftime('%Y-%m')
      churches = ::ChurchFilter.new(params, current_user).filter(church_scope)
      return churches unless params[:long_min]
      ::ChurchClusterer.new(params).cluster(churches)
    end
  end
end
