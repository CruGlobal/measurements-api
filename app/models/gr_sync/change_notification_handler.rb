# frozen_string_literal: true

module GrSync
  class ChangeNotificationHandler
    def initialize(entity_type_name, entity_id)
      @model = SubscribedEntities.model_for_name(entity_type_name)
      @gr_id = entity_id
    end

    def created_notification
      created_or_updated_notification
    end

    def updated_notification
      created_or_updated_notification
    end

    def deleted_notification
      # Do not delete entities, for now
      # @model.find_by(gr_id: @gr_id).try(&:destroy!)
    end

    private

    def created_or_updated_notification
      entity = GlobalRegistryClient.client.find(@gr_id)
      @model.create_or_update_from_entity!(entity)
    rescue ActiveRecord::RecordInvalid => e
      Rollbar.error(e, gr_id: @gr_id, entity: entity)
    end
  end
end
