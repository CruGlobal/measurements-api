module GrSync
  class SubscribedEntities
    class << self
      # We don't subscribe to changes from Assignment to prevent another system
      # from adding an Assignment entity and thus gaining access to data in the
      # measurements api.
      ENTITY_MODELS = [::Ministry, ::Person].freeze

      NAMES_TO_MODELS = Hash[ENTITY_MODELS.map { |m| [m.entity_type, m] }].freeze
      ENTITY_NAMES = NAMES_TO_MODELS.values.freeze

      def entity_type_ids
        EntityTypeFinder.entity_type_ids(ENTITY_NAMES)
      end

      def model_for_entity(entity)
        model_for_name(entity.keys.first)
      end

      def model_for_name(name)
        # Give an exception if you try to find a model with no name
        NAMES_TO_MODELS.fetch(name)
      end
    end
  end
end
