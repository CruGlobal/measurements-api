# frozen_string_literal: true
# Be sure to restart your server when you modify this file.
require Rails.root.join('config', 'initializers', 'redis')

Rails.application.config.session_store :redis_store, servers: {
  host: Redis.current.client.host,
  port: Redis.current.client.port,
  db: 2,
  namespace: 'measurements-api:session:',
  expires_in: 2.days
}
