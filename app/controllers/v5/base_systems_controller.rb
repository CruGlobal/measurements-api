module V5
  module BaseSystemsController
    extend ActiveSupport::Concern
    include V5::SystemAccessTokenProtectedConcern

    included do
      around_action :with_token
      skip_around_action :with_current_power
    end

    def current_user
      nil
    end

    def with_token(&_)
      GlobalRegistryParameters.current = { access_token: @access_token, xff: request.remote_ip }
      yield
    ensure
      GlobalRegistryParameters.current = nil
    end
  end
end
