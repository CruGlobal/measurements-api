# frozen_string_literal: true
module GrSync
  class SubscriptionManager
    def initialize(entity_type_ids, endpoint)
      @entity_type_ids = entity_type_ids
      @endpoint = endpoint
    end

    def ensure_subscribed_to_all
      missing_entity_type_ids = @entity_type_ids - subscribed_entity_type_ids
      missing_entity_type_ids.each(&method(:subscribe))
    end

    private

    def subscribed_entity_type_ids
      subscription_client.get_all_pages
                         .select { |sub| sub['endpoint'] == @endpoint }
                         .map { |sub| sub['entity_type_id'] }
    end

    def subscribe(entity_type_id)
      subscription_client.post(
        subscription: {
          entity_type_id: entity_type_id, endpoint: @endpoint
        }
      )
    end

    def subscription_client
      @subscription_client ||= GlobalRegistryClient.client(:subscription)
    end
  end
end
