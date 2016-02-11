module V5
  class ChurchesController < V5::BaseController
    include CruLib::AccessTokenProtectedConcern

    def index
      render json: filtered_churches, serializer_context_class: V5::ChurchArraySerializer
    end

    def create
      build_church
      save_note or render_errors
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

    def save_note
      render @church, status: 201 if @church.save
    end

    def church_params
      church_params = params[:note]
      church_params ? church_params.permit(:title, :text, :published) : {}
    end

    def church_scope
      Church.all
    end

    def filtered_churches
      ::ChurchFilter.new(params, current_user).filter(church_scope)
    end
  end
end
