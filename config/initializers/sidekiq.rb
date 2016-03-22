# frozen_string_literal: true
require 'sidekiq'
require Rails.root.join('config', 'initializers', 'redis')

sidekiq_project_name = ENV.fetch('PROJECT_NAME') { Rails.application.class.parent.to_s }
sidekiq_namespace = [sidekiq_project_name, Rails.env, 'resque'].join(':')

Sidekiq.configure_client do |config|
  config.redis = { url: Redis.current.client.id, namespace: sidekiq_namespace }
end

if Sidekiq::Client.method_defined? :reliable_push!
  Sidekiq::Client.reliable_push!
end

Sidekiq.configure_server do |config|
  config.reliable_fetch!
  config.reliable_scheduler!
  config.redis = { url: Redis.current.client.id, namespace: sidekiq_namespace }
end

Sidekiq.default_worker_options = {
  backtrace: true,
  unique_expiration: 22.days,
  log_duplicate_payload: true,
  unique: :until_and_while_executing
}
