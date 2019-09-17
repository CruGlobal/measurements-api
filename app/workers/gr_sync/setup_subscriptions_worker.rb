# frozen_string_literal: true

module GrSync
  class SetupSubscriptionsWorker
    include Sidekiq::Worker

    def perform
      SubscriptionManager.new(SubscribedEntities.entity_type_ids, endpoint).ensure_subscribed_to_all
    end

    private

    def endpoint
      Rails.application.routes.url_helpers.gr_sync_notifications_url(host: ENV.fetch("SITE_HOST"), protocol: "https")
    end
  end
end
