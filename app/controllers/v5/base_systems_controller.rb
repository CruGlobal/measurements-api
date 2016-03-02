module V5
  class BaseSystemsController < BaseController
    include V5::AccessTokenProtectedConcern

    before_action :authenticate_sys_request

    def current_token
      @access_token
    end
  end
end
