module V5
  class BaseSystemsController < BaseController
    include V5::SystemAccessTokenProtectedConcern

    before_action :authenticate_request
    around_filter :with_token

    def with_token(&action)
      SystemAccessToken.current = @access_token
      action.call
    ensure
      SystemAccessToken.current = nil
    end
  end
end
