# frozen_string_literal: true
# Sidekiq / sidekiq-unique-jobs use Redis in testing
# Use this to clear unique locks between tests
def clear_uniqueness_locks
  Sidekiq.redis do |redis|
    redis.keys('*unique*').each { |k| redis.del(k) }
  end
end
