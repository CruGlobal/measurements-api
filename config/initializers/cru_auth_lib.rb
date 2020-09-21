# frozen_string_literal: true

require "cru_auth_lib"

CruAuthLib.configure do |config|
  config.redis_host = ENV.fetch("SESSION_REDIS_HOST")
end
