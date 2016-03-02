module V5
  class BaseSystemsController < BaseController
    include V5::SystemAccessTokenProtectedConcern

    before_action :authenticate_request

    def current_token
      @access_token
    end
  end
end
