require 'sidekiq'
require Rails.root.join('config', 'initializers', 'redis')

Sidekiq.configure_client do |config|
  config.redis = { url: $redis.client.id,
                   namespace: "MAPI:#{Rails.env}:resque"}
end

Sidekiq::Client.reliable_push!

Sidekiq.configure_server do |config|
  config.reliable_fetch!
  config.reliable_scheduler!
  config.redis = { url: $redis.client.id,
                   namespace: "MAPI:#{Rails.env}:resque"}
  config.failures_default_mode = :exhausted
end
