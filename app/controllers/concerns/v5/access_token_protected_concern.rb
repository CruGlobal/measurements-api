module V5
  module AccessTokenProtectedConcern
    extend ActiveSupport::Concern

    protected

    def authenticate_request
      authenticate_token || render_unauthorized
    end

    def authenticate_sys_request
      authenticate_sys_token || render_unauthorized
    end

    def authenticate_token
      token = oauth_access_token_from_header || access_token_from_url
      return unless oauth_access_token_from_header
      @access_token = CruLib::AccessToken.read(token)
    end

    def authenticate_sys_token
      token = oauth_access_token_from_header || access_token_from_url(:access_token)
      return unless token && check_token(token)
      @access_token = token
    end

    # grabs access_token from header if one is present
    def oauth_access_token_from_header
      auth_header = request.env['HTTP_AUTHORIZATION'] || ''
      match = auth_header.match(/^Bearer\s(.*)/)
      return match[1] if match.present?
      false
    end

    # grabs access_token from url param if present
    def access_token_from_url(param = nil)
      param ||= :token
      params[param]
    end

    def render_unauthorized
      headers['WWW-Authenticate'] =
        %(CAS realm="Application", casUrl="#{ENV['CAS_BASE_URL']}", service="#{v5_token_index_url}")
      api_error 'Bad token', status: 401
    end

    def check_token(token)
      gr = GlobalRegistry::System.new(access_token: token)
      gr.get(limit: 1).present?
    rescue RestClient::BadRequest
      false
    end
  end
end
