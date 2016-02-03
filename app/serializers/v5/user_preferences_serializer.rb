module V5
  class UserPreferencesSerializer < ActiveModel::Serializer
    PROPERTY_MAP_VIEWS = 'default_map_views'.freeze
    PROPERTY_MEASUREMENT_STATES = 'default_measurement_states'.freeze
    PROPERTY_CONTENT_LOCALES = 'content_locales'.freeze

    has_many :default_map_views
    has_many :default_measurement_states
    attribute :content_locales

    def attributes(args)
      # convert preferences to a hash
      raw_prefs = object.user_preferences.to_a.each_with_object({}) { |p, h| h[p.name] = p.value }
      super(args).merge(raw_prefs)
    end

    def content_locales
      locales = {}
      object.user_content_locales.each do |locale|
        locales[locale.ministry_id] = locale.locale
      end
      locales
    end

    def default_map_views
      object.user_map_views.map do |view|
        {
          ministry_id: view.ministry_id,
          location: {
            latitude: view.lat,
            longitude: view.long
          },
          location_zoom: view.zoom
        }
      end
    end

    def default_measurement_states
      states = {}
      Constants::MCCS.each do |mcc|
        mcc_data = {}
        object.user_measurement_states.where(mcc: mcc).each do |state|
          mcc_data[state.perm_link_stub] = state.visible ? 1 : 0
        end
        states[mcc] = mcc_data
      end
      states
    end
  end
end
