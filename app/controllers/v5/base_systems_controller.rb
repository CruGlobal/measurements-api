module V5
  class BaseSystemsController < BaseController
    include V5::SystemAccessTokenProtectedConcern

    before_action :authenticate_request
    around_action :with_token

    def with_token(&_)
      SystemAccessToken.current = @access_token
      yield
    ensure
      SystemAccessToken.current = nil
    end
  end
end
