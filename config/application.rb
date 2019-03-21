# frozen_string_literal: true
require_relative 'boot'

# require 'rails/all'
require 'active_model/railtie'
# require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
# require 'action_mailer/railtie'
# require 'action_view/railtie'
# require 'sprockets/railtie'

require_relative '../app/middleware/rack_reset_gr_client'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MeasurementsApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    config.generators do |g|
      g.test_framework :rspec, fixture: true
      g.view_specs false
      g.helper_specs false
      g.template_engine false
      g.stylesheets false
      g.javascripts false
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
    end

    config.middleware.use RackResetGrClient

    config.log_formatter = ::Logger::Formatter.new

    # RubyCAS config
    config.rubycas.cas_base_url = ENV.fetch('CAS_BASE_URL')
    config.rubycas.logger = Rails.logger
  end
end
