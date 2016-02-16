module V5
  class BaseUserController < BaseController
    include V5::AccessTokenProtectedConcern
    include Consul::Controller

    before_action :authenticate_request
    current_power do
      Power.new(current_user, params[:ministry_id])
    end

    protected

    def redis_ticket_key(ticket)
      ['measurements_api:service_ticket', ticket].join(':')
    end

    def current_user
      return nil unless @access_token
      @current_user ||= Person.person(@access_token.key_guid)
    end
  end
end
