module V5
  class BaseController < ApplicationController
    protected

    def redis_ticket_key(ticket)
      ['measurements_api:service_ticket', ticket].join(':')
    end

    def api_error(message, options = {})
      render(
        json: ApiError.new(message: message),
        status: options[:status] || :bad_request,
        serializer: V5::ApiErrorSerializer
      )
    end

    def current_user
      return nil unless @access_token
      @current_user ||= Person.find_or_initialize(@access_token.key_guid)
    end

    # cru_lib calls render_error, alias it to api_error
    alias render_error api_error
  end
end
