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
      g.fixture_replacement :factory_girl
    end

    config.middleware.insert_before 0, 'Rack::Cors' do
      allow do
        origins '*'
        resource '*',
                 headers: :any,
                 methods: [:get, :post, :delete, :put, :patch, :options, :head],
                 max_age: 0
      end
    end

    config.log_formatter = ::Logger::Formatter.new

    # RubyCAS config
    config.rubycas.cas_base_url = ENV.fetch('CAS_BASE_URL')
    config.rubycas.logger = Rails.logger
  end
end
