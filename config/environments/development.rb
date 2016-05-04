# frozen_string_literal: true
Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  # config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
  config.active_record.raise_in_transactional_callbacks = true

  # SITE_HOST in development can be helpful for testing webhooks with ngrok
  Rails.application.routes.default_url_options[:host] = ENV['SITE_HOST'] || 'localhost:3000'

  HttpLogger.log_headers = true
  HttpLogger.logger = Logger.new(STDOUT)
  HttpLogger.collapse_body_limit = 10_000
  HttpLogger.ignore = [/newrelic\.com/]

  # Allows us to turn on logging of body and resopnse when wanted
  HttpLogger.log_request_body  = ENV['LOG_REQUEST_BODY'].present?
  HttpLogger.log_response_body = ENV['LOG_RESPONSE_BODY'].present?

  # Allow us to turn off HTTP logging with an env var
  HttpLogger.logger.level = Logger::Severity::UNKNOWN if ENV['NO_HTTP_LOGGER']

  config.middleware.insert_before 0, 'Rack::Cors' do
    allow do
      origins '*'
      resource '*',
               headers: :any,
               methods: [:get, :post, :delete, :put, :patch, :options, :head],
               max_age: 0
    end
  end
end
