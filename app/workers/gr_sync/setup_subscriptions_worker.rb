module GrSync
  class SetupSubscriptionsWorker
    include Sidekiq::Worker

    ENTITY_MODELS = [::Ministry, ::Person].freeze
    ENTITY_NAMES = ENTITY_MODELS.map(&:entity_type)

    def perform
      SubscriptionManager.new(entity_type_ids, endpoint).ensure_subscribed_to_all
    end

    private

    def entity_type_ids
      EntityTypeFinder.entity_type_ids(ENTITY_NAMES)
    end

    def endpoint
      Rails.application.routes.url_helpers.gr_sync_notifications_url
    end
  end
end
