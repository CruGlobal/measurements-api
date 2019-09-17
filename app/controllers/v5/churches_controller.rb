# frozen_string_literal: true

module V5
  class ChurchesController < V5::BaseUserController
    power :churches, map: {[:create, :update] => :changeable_churches}, as: :church_scope

    def index
      churches = filtered_churches.to_a
      church_ids = churches.collect { |c| c.id if c.is_a? Church }.compact
      render json: churches,
             serializer_context_class: V5::ChurchArraySerializer,
             scope: {period: params[:period],
                     values: ChurchValue.values_for(church_ids, params[:period]),}
    end

    def create
      build_church
      save_church || render_errors
    end

    def update
      load_church
      create
    end

    private

    def request_power
      ministry_id = if params[:action] == "update"
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
      render json: @church, status: save_status_code if @church.save
    end

    def render_errors
      render json: @church.errors.messages, status: :bad_request
    end

    def church_params
      permitted_params = [:name, :ministry_id, :contact_name, :contact_email, :contact_mobile,
                          :latitude, :longitude, :start_date, :jf_contrib, :parent_id, :development,
                          :size, :security,]
      permitted_params = params.permit(permitted_params)
      permitted_params[:created_by_id] = current_user.id
      if permitted_params[:ministry_id]
        permitted_params[:ministry_id] = Ministry.find_by(gr_id: permitted_params[:ministry_id]).try(:id)
      end
      if permitted_params[:security] && permitted_params[:security].to_i == 0
        permitted_params[:security] = 1
      end
      fix_enum_params(permitted_params, :security, :development)
    end

    def church_filters_params
      params[:period] ||= Time.zone.today.strftime("%Y-%m")
      [:long_max, :long_min, :lat_max, :lat_min].each do |s|
        params[s] = params[s].to_f if params.key? s
      end
      params
    end

    def filtered_churches
      churches = ::ChurchFilter.new(church_filters_params).filter(church_scope)
      churches = churches.includes(:created_by, :parent)
      return churches unless params[:long_min]
      ::ChurchClusterer.new(church_filters_params).cluster(churches)
    end
  end
end
