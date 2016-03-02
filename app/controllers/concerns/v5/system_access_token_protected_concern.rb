module V5
  module SystemAccessTokenProtectedConcern
    extend ActiveSupport::Concern

    protected

    def authenticate_request
      authenticate_token || render_unauthorized
    end

    def authenticate_token
      token = oauth_access_token_from_header || access_token_from_url
      return unless token
      @access_token = check_token(token)
    end

    # grabs access_token from header if one is present
    def oauth_access_token_from_header
      auth_header = request.env['HTTP_AUTHORIZATION'] || ''
      match = auth_header.match(/^Bearer\s(.*)/)
      return match[1] if match.present?
      nil
    end

    def render_unauthorized
      headers['WWW-Authenticate'] =
        %(CAS realm="Application", casUrl="#{ENV['CAS_BASE_URL']}", service="#{v5_token_index_url}")
      api_error 'Bad token', status: 401
    end

    def access_token_from_url
      params[:access_token]
    end

    def check_token(token)
      resp = GlobalRegistry::System.new(access_token: token).get(limit: 1)
      resp.present? ? token : nil
    rescue RestClient::BadRequest
      nil
    end
  end
end
