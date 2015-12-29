module V5
  class BaseController < ApplicationController

    protected

    def redis_ticket_key(ticket)
      ['measurements_api:service_ticket', ticket].join(':')
    end

    def api_error(message, options = {})
      render(
        json: ApiErrorPresenter.new(ApiError.new(message: message)),
        status: options[:status] || :bad_request
      )
    end

    # cru_lib calls render_error, alias it to api_error
    alias_method :render_error, :api_error
  end
end
