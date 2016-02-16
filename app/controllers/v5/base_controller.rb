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
      @current_user ||= Person.person(@access_token.key_guid)
    end

    # cru_lib calls render_error, alias it to api_error
    alias render_error api_error

    def post_params
      ::ActionController::Parameters.new(request.request_parameters)
    end

    def get_params # rubocop:disable Style/AccessorMethodName
      ::ActionController::Parameters.new(request.query_parameters)
    end

    def fix_enum_params(params, *enum_fields)
      enum_fields.each do |f|
        # cast to int if it is a int wrapped in quotes
        params[f] = params[f].to_i if params[f] == params[f].to_i.to_s
      end
      params
    end
  end
end
