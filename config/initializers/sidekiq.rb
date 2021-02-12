# frozen_string_literal: true

require "redis"
require "sidekiq"
require "sidekiq/web"

redis_conf = YAML.safe_load(ERB.new(File.read(Rails.root.join("config", "redis.yml"))).result, [Symbol], [], true)["sidekiq"]

Redis.current = Redis.new(redis_conf)

redis_settings = {url: Redis.current.id,
                  id: nil,}

Sidekiq.configure_client do |config|
  config.redis = redis_settings

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

if Sidekiq::Client.method_defined? :reliable_push!
  Sidekiq::Client.reliable_push!
end

Sidekiq.configure_server do |config|
  config.super_fetch!
  config.reliable_scheduler!
  config.redis = redis_settings

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqResetGrClient
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  SidekiqUniqueJobs::Server.configure(config)
end

Sidekiq::Web.set :session_secret, ENV.fetch("SECRET_KEY_BASE", "0987654321fedcba")
Sidekiq::Web.use Rack::Auth::Basic do |username, password|
  username == ENV.fetch("SIDEKIQ_USERNAME") && password == ENV.fetch("SIDEKIQ_PASSWORD")
end

Sidekiq.default_worker_options = {
  backtrace: true,
  log_duplicate_payload: true,
  lock: :until_and_while_executing,
}
