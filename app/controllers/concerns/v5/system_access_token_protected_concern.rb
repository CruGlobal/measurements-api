# frozen_string_literal: true

module V5
  module SystemAccessTokenProtectedConcern
    extend ActiveSupport::Concern

    SYSTEM_TOKEN_AUTH_TIMEOUT = 2.hours

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
      auth_header = request.env["HTTP_AUTHORIZATION"] || ""
      match = auth_header.match(/^Bearer\s(.*)/)
      return match[1] if match.present?
      nil
    end

    def render_unauthorized
      headers["WWW-Authenticate"] =
        %(CAS realm="Application", casUrl="#{ENV["CAS_BASE_URL"]}", service="#{v5_token_index_url}")
      api_error "Bad token", status: 401
    end

    def access_token_from_url
      params[:access_token]
    end

    def check_token(token)
      return token if token_has_auth(token)

      resp = GlobalRegistry::System.new(
        base_url: ENV["GLOBAL_REGISTRY_BACKEND_URL"],
        access_token: token,
        xff: request.headers["HTTP_X_FORWARDED_FOR"]
      ).get(limit: 1)
      return unless resp.present?

      Rails.cache.write(cache_key(token), "1", expires_in: SYSTEM_TOKEN_AUTH_TIMEOUT)

      token
    rescue RestClient::BadRequest, RuntimeError
      nil
    end

    def token_has_auth(token)
      Rails.cache.read(cache_key(token))
    end

    def cache_key(token)
      "token:#{token}:authenticated"
    end
  end
end
