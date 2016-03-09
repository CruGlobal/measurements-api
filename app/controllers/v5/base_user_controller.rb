module V5
  class BaseUserController < BaseController
    include V5::AccessTokenProtectedConcern
    include Consul::Controller

    rescue_from Consul::Powerless, with: :render_consul_powerless

    before_action :authenticate_request
    current_power do
      request_power
    end

    protected

    def redis_ticket_key(ticket)
      ['measurements_api:service_ticket', ticket].join(':')
    end

    def current_user
      return nil unless @access_token
      @current_user ||= Person.person(@access_token.key_guid)
    end

    def request_power
      Power.new(current_user, params[:ministry_id])
    end

    def render_consul_powerless(exception)
      api_error(exception.message, status: :unauthorized)
    end

    def render_not_found
      api_error 'Not Found', status: :not_found
    end
  end
end
