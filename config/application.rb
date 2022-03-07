# frozen_string_literal: true

require_relative "boot"

# require 'rails/all'
require "active_model/railtie"
# require 'active_job/railtie'
require "active_record/railtie"
require "action_controller/railtie"
# require 'action_mailer/railtie'
# require 'action_view/railtie'
# require 'sprockets/railtie'

require_relative "../app/middleware/rack_reset_gr_client"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative "../lib/log/logger"
module MeasurementsApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    redis_conf = YAML.safe_load(ERB.new(File.read(Rails.root.join("config", "redis.yml"))).result, [Symbol], [], true)["cache"]
    redis_conf[:url] = "redis://" + redis_conf[:host] + "/" + redis_conf[:db].to_s
    config.cache_store = :redis_cache_store, redis_conf

    # Enable ougai
    if Rails.env.development? || Rails.const_defined?("Console")
      config.logger = Log::Logger.new(STDOUT)
    elsif !Rails.env.test? # use default logger in test env
      config.logger = Log::Logger.new(Rails.root.join("log", "datadog.log"))
    end

    config.generators do |g|
      g.test_framework :rspec, fixture: true
      g.view_specs false
      g.helper_specs false
      g.template_engine false
      g.stylesheets false
      g.javascripts false
      g.fixture_replacement :factory_bot, dir: "spec/factories"
    end

    config.middleware.use RackResetGrClient

    config.log_formatter = ::Logger::Formatter.new

    # RubyCAS config
    config.rubycas.cas_base_url = ENV.fetch("CAS_BASE_URL")
    config.rubycas.logger = Rails.logger
  end
end
