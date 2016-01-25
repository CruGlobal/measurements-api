module GlobalRegistry
  class Ministry
    include ActiveModel::Model
    include GlobalRegistry::EntityConcern

    ENTITY_TYPE = 'ministry'.freeze

    attr_accessor :id,
                  :name,
                  :parent_id,
                  :lmi_hide,
                  :lmi_show,
                  :location_zoom,
                  :location,
                  :has_slm,
                  :has_llm,
                  :has_gcm,
                  :has_ds,
                  :is_active,
                  :default_mcc

    def method_missing(*_args)
      # swallow missing method calls
      nil
    end

    class << self
      def all
        fail 'block required' unless block_given?
        all_active do |ministry|
          yield ministry
        end
        all_missing_active do |ministry|
          yield ministry
        end
      end

      def find_by_ministry_id(ministry_id)
        gr_ministry = find_by(ministry_id, levels: 1)
        return if gr_ministry.nil? || !gr_ministry.key?('ministry')
        create_from_entity(gr_ministry['ministry'])
      end

      private

      def all_active
        fail 'block required' unless block_given?
        find_each(
          entity_type: ENTITY_TYPE,
          levels: 0,
          fields: 'name',
          'filters[parent_id:exists]': true,
          'filters[is_active]': true
        ) do |ministry|
          yield create_from_entity(ministry)
        end
      end

      def all_missing_active
        fail 'block required' unless block_given?
        find_each(
          entity_type: ENTITY_TYPE,
          levels: 0,
          fields: 'name',
          'filters[parent_id:exists]': true,
          'filters[is_active:not_exists]': true
        ) do |ministry|
          yield create_from_entity(ministry)
        end
      end

      def create_from_entity(entity = {})
        # Remove keys that do not map to Model attributes
        # params = entity.reject { |k| !GlobalRegistry::Ministry.attribute_method? k.to_s }
        GlobalRegistry::Ministry.new(entity)
      end
    end
  end
end
