# frozen_string_literal: true

module GrSync
  class EntityTypeFinder
    class << self
      def entity_type_ids(names)
        entity_types(names).map { |entity_type| entity_type["id"] }
      end

      def entity_types(names)
        GlobalRegistry::EntityType.new.get_all_pages("filters[name][]" => names)
      end
    end
  end
end
