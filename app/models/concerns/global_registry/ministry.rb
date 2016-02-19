module GlobalRegistry
  module Ministry
    extend ActiveSupport::Concern

    # Map global registry mcc property names to MCC value
    ENTITY_MCCS = {
      has_slm: ::Ministry::MCC_SLM,
      has_llm: ::Ministry::MCC_LLM,
      has_gcm: ::Ministry::MCC_GCM,
      has_ds: ::Ministry::MCC_DS
    }.freeze

    included do
      before_create :create_entity, if: 'gr_id.blank?'
    end

    # Getter/Setters for GR
    def location=(value)
      self.latitude = value[:latitude] if value.key? :latitude
      self.longitude = value[:longitude] if value.key? :longitude
    end

    def location
      # TODO: walk parent ministries to find lat/lng if missing
      { latitude: latitude, longitude: longitude }
    end

    def lmi_show=(lmi)
      lmi = lmi.split(',') if lmi.is_a? String
      super lmi
    end

    def lmi_hide=(lmi)
      lmi = lmi.split(',') if lmi.is_a? String
      super lmi
    end

    # Filter to create Global Registry Entity before creating ActiveRecord entry
    def create_entity
      entity = super
      # update ministry_id from GR entity id
      self.gr_id = entity[:id]
    end

    # Model attribute value to Global Registry Entity property value
    # Return nil to remove property from the request
    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength
    def attribute_to_entity_property(property)
      case property.to_sym
      when :id
        gr_id
      when :parent_id
        parent.try(:gr_id)
      when :client_integration_id
        min_code
      when :has_ds, :has_llm, :has_gcm, :has_slm
        mcc = ENTITY_MCCS[property]
        mccs.include? mcc
      when :lmi_show
        lmi_show.empty? ? nil : lmi_show.join(',')
      when :lmi_hide
        lmi_hide.empty? ? nil : lmi_hide.join(',')
      when :location
        loc = location
        loc.delete_if { |_k, v| v.nil? }
        return nil if loc.empty?
        loc[:client_integration_id] = min_code
        loc
      else
        super
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength

    # Set self attribute value from Global Registry Entity property and value
    def attribute_from_entity_property(property, value = nil)
      case property.to_sym
      when :id
        super(:gr_id, value)
      when :parent_id
        self.parent_gr_id = value
        super(:parent_id, self.class.find_by(gr_id: value).try(:id))
      when :has_ds, :has_llm, :has_gcm, :has_slm
        mcc = ENTITY_MCCS[property]
        if value
          mccs << mcc unless mccs.include? mcc
        else
          mccs.delete mcc
        end
      else
        super(property, value)
      end
    end

    module ClassMethods
      # Global Registry Entity type
      def entity_type
        'ministry'
      end

      # Global Registry Entity Properties to sync
      def entity_properties
        [:name, :parent_id, :min_code, :location, :location_zoom, :lmi_hide, :lmi_show,
         :hide_reports_tab, :has_slm, :has_llm, :has_gcm, :has_ds].concat(super)
      end

      def all_gr_ministries
        fail 'block required' unless block_given?
        all_active_ministries do |entity|
          yield entity
        end
        all_ministries_missing_active do |entity|
          yield entity
        end
      end

      # Find id, name for all active ministries
      def all_active_ministries
        fail 'block required' unless block_given?
        find_entities_each(
          entity_type: 'ministry',
          levels: 0,
          fields: 'name',
          'filters[parent_id:exists]': true,
          'filters[is_active]': true
        ) do |entity|
          yield entity
        end
      end

      # Find id, name for all ministries missing the active property
      def all_ministries_missing_active
        fail 'block required' unless block_given?
        find_entities_each(
          entity_type: 'ministry',
          levels: 0,
          fields: 'name',
          'filters[parent_id:exists]': true,
          'filters[is_active:not_exists]': true
        ) do |entity|
          yield entity
        end
      end
    end
  end
end
