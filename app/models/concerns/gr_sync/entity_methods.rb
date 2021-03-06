# frozen_string_literal: true

module GrSync
  module EntityMethods
    extend ActiveSupport::Concern

    # Creates the entity in Global Registry
    def create_entity(_options = {})
      # TODO: Handle exceptions
      entity = self.class.client.post(to_entity)["entity"][self.class.entity_type].with_indifferent_access
      self.gr_id = entity[:id]
    end

    # Updates self from Global Registry entity with given :id
    # Returns raw entity hash or nil
    def update_from_entity(params = {})
      return if attribute_to_entity_property(:id).nil?
      # TODO: Handle exceptions
      from_entity self.class.find_entity(attribute_to_entity_property(:id), params)
    end

    def async_update_entity
      # Use the root global registry key by default which is what we do for
      # updates to ministries, people and assignments.
      GrSync::EntityUpdatePush.queue_with_root_gr(self)
    end

    def attribute_to_entity_property(property)
      respond_to?(property) ? send(property) : nil
    end

    def attribute_from_entity_property(property, value = nil)
      method = "#{property}="
      send(method, value) if respond_to?(method)
    end

    def to_entity
      properties = self.class.entity_properties.collect { |property|
        value = attribute_to_entity_property(property)
        value.nil? ? nil : [property, value]
      }.compact.to_h
      {entity: Hash[self.class.entity_type, properties]}
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
      def client
        # By default use the root key for interactions with global registry
        GlobalRegistryClient.new.entities
      end

      def entity_type
        to_s.underscore
      end

      def entity_properties
        %i[id client_integration_id]
      end

      def create_or_update_from_entity!(entity)
        record = find_or_initialize_by(gr_id: entity.values.first["id"])
        record.from_entity(entity)
        record.save!
      end

      def find_entity(id, params = {})
        response = client.find(id, params)
        response["entity"].with_indifferent_access if response.key?("entity")
      rescue RestClient::InternalServerError => e
        Rollbar.error(e, id: id, params: params)
        nil
      rescue RestClient::ResourceNotFound
        nil
      end

      def find_entity_by(params = {})
        results = client.get(params)["entities"]
        return nil unless results[0] && results[0]
        results[0].with_indifferent_access
      rescue RestClient::ResourceNotFound
        nil
      end
    end
  end
end
