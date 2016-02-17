module GlobalRegistry
  module EntityMethods
    extend ActiveSupport::Concern

    # Creates the entity in Global Registry
    def create_entity(_options = {})
      # TODO: Handle exceptions
      GlobalRegistry::Entity.post(to_entity)['entity'][self.class.entity_type].with_indifferent_access
    end

    # Updates self from Global Registry entity with given :id
    # Returns raw entity hash or nil
    def update_from_entity(params = {})
      return if attribute_to_entity_property(:id).nil?
      # TODO: Handle exceptions
      from_entity self.class.find_entity(attribute_to_entity_property(:id), params)
    end

    def update_entity(_params = {})
      # TODO: implement
    end

    def attribute_to_entity_property(property)
      respond_to?(property) ? send(property) : nil
    end

    def attribute_from_entity_property(property, value = nil)
      method = "#{property}="
      send(method, value) if respond_to?(method)
    end

    def to_entity
      properties = self.class.entity_properties.collect do |property|
        value = attribute_to_entity_property(property)
        value.nil? ? nil : [property, value]
      end.compact.to_h
      { entity: Hash[self.class.entity_type, properties] }
    end

    def from_entity(entity = {})
      return unless entity.present? && entity.key?(self.class.entity_type)
      entity = entity[self.class.entity_type].with_indifferent_access
      self.class.entity_properties.each do |property|
        attribute_from_entity_property(property, entity[property]) if entity.key? property
      end
      entity
    end

    module ClassMethods
      def entity_type
        to_s.underscore
      end

      def entity_properties
        %i(id client_integration_id)
      end

      def create_from_entity(_params = {})
        # TODO: implement
      end

      def find_entity(id, params = {})
        response = GlobalRegistry::Entity.find(id, params)
        response['entity'].with_indifferent_access if response.key?('entity')
      rescue RestClient::ResourceNotFound
        nil
      end

      def find_entity_by(params = {})
        results = GlobalRegistry::Entity.get(params)['entities']
        return nil unless results[0] && results[0]
        results[0].with_indifferent_access
      rescue RestClient::ResourceNotFound
        nil
      end

      # Find Entities (internally uses find_entities_in_batches)
      def find_entities_each(params = {})
        fail 'block required' unless block_given?
        find_entities_in_batches(params) do |entities|
          entities.each do |entity|
            next unless entity.key? params[:entity_type]
            yield entity.fetch(params[:entity_type]).with_indifferent_access
          end
        end
      end

      # Find Entities in paged batches
      def find_entities_in_batches(params = {})
        fail 'block required' unless block_given?
        params['page'] = 1 unless params.key? 'page'
        params['per_page'] = 50 unless params.key? 'per_page'
        loop do
          response = GlobalRegistry::Entity.get(params)
          yield response['entities'] if response.key? 'entities'
          break if response.key?('meta') && (response['meta']['next_page'] == false)
          params['page'] += 1
        end
      end
    end
  end
end
