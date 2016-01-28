module GlobalRegistry
  class Ministry < GlobalRegistry::EntityModel
    ENTITY_TYPE = 'ministry'.freeze

    entity_property :name
    entity_property :parent_id
    entity_property :lmi_hide
    entity_property :lmi_show
    entity_property :location_zoom
    entity_property :location
    entity_property :has_slm
    entity_property :has_llm
    entity_property :has_gcm
    entity_property :has_ds
    entity_property :is_active
    entity_property :default_mcc

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
        gr_ministry = find_by(ministry_id, 'filters[owned_by]': 'all', levels: 1)
        return if gr_ministry.nil? || !gr_ministry.key?('ministry')
        GlobalRegistry::Ministry.new(gr_ministry['ministry'])
      end

      private

      # Find id, name for all active ministries
      def all_active
        fail 'block required' unless block_given?
        find_each(
          entity_type: ENTITY_TYPE,
          levels: 0,
          fields: 'name',
          'filters[parent_id:exists]': true,
          'filters[is_active]': true
        ) do |ministry|
          yield GlobalRegistry::Ministry.new(ministry)
        end
      end

      # Find id, name for all ministries missing the active property
      def all_missing_active
        fail 'block required' unless block_given?
        find_each(
          entity_type: ENTITY_TYPE,
          levels: 0,
          fields: 'name',
          'filters[parent_id:exists]': true,
          'filters[is_active:not_exists]': true
        ) do |ministry|
          yield GlobalRegistry::Ministry.new(ministry)
        end
      end
    end
  end
end
