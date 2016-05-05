# frozen_string_literal: true
require File.expand_path('../boot', __FILE__)

# require 'rails/all'
require 'active_model/railtie'
# require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
# require 'action_mailer/railtie'
# require 'action_view/railtie'
# require 'sprockets/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MeasurementsApi
  class Application < Rails::Application
    config.assets.enabled = false
    config.generators do |g|
      g.test_framework :rspec, fixture: true
      g.view_specs false
      g.helper_specs false
      g.template_engine false
      g.stylesheets false
      g.javascripts false
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
    end

    config.middleware.use '::RackResetGrClient'

    config.log_formatter = ::Logger::Formatter.new

    # RubyCAS config
    config.rubycas.cas_base_url = ENV.fetch('CAS_BASE_URL')
    config.rubycas.logger = Rails.logger

    # Use Redis as cache store
    config.cache_store = :redis_store, {
      host: Redis.current.client.host,
      port: Redis.current.client.port,
      db: 2,
      namespace: 'measurements-api:cache:',
      expires_in: 1.day
    }
  end
end
