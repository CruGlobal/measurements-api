# frozen_string_literal: true
require 'redis'
require 'sidekiq'
require 'sidekiq/web'
require 'datadog/statsd'

redis_conf = YAML.safe_load(ERB.new(File.read(Rails.root.join('config', 'redis.yml'))).result, [], [], true)['sidekiq']

Redis.current = Redis.new(redis_conf)

redis_settings = { url: Redis.current.client.id,
                   namespace: redis_conf['namespace'] }

Sidekiq.configure_client do |config|
  config.redis = redis_settings
end

if Sidekiq::Client.method_defined? :reliable_push!
  Sidekiq::Client.reliable_push!
end

Sidekiq.configure_server do |config|
  config.reliable_fetch!
  config.reliable_scheduler!
  config.redis = redis_settings

  config.server_middleware do |chain|
    chain.add SidekiqResetGrClient
  end
end

Sidekiq::Web.set :session_secret, ENV.fetch('SECRET_KEY_BASE', '0987654321fedcba')
Sidekiq::Web.use Rack::Auth::Basic do |username, password|
  username == ENV.fetch('SIDEKIQ_USERNAME') && password == ENV.fetch('SIDEKIQ_PASSWORD')
end

Sidekiq.default_worker_options = {
  backtrace: true,
  unique_expiration: 22.days,
  log_duplicate_payload: true,
  unique: :until_and_while_executing
}

unless Rails.env.development? || Rails.env.test?
  Sidekiq::Pro.dogstatsd = -> { Datadog::Statsd.new(ENV['DATADOG_HOST'], ENV['DATADOG_PORT']) }
end
