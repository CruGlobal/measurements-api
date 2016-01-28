module GlobalRegistry
  class EntityModel
    include GlobalRegistry::EntityConcern
    ATTR_VALUE = :value

    class << self
      def entity_property(property, options = {})
        property = property.to_sym
        options = options.symbolize_keys

        # Getter
        define_method property do
          get_property(property, options)
        end
      end
    end

    def initialize(entity)
      self.entity = entity.with_indifferent_access
      super()
    end

    def method_missing(symbol, *args)
      return get_property(symbol) if entity.key? symbol
      super
    end

    def id
      entity[:id] if entity.key? :id
    end

    protected

    attr_accessor :entity

    def get_property(name, options = {})
      name = options.key?(:path) ? options[:path] : name
      return nil unless entity.key? name
      prop = entity.fetch name
      return prop[ATTR_VALUE] if prop.is_a? Hash
      return prop[0][ATTR_VALUE] if prop.is_a? Array
      prop
    end
  end
end
