module V5
  class UserPreferencesSerializer < ActiveModel::Serializer
    PROPERTY_MAP_VIEWS = 'default_map_views'.freeze
    PROPERTY_MEASUREMENT_STATES = 'default_measurement_states'.freeze
    PROPERTY_CONTENT_LOCALES = 'content_locales'.freeze

    attributes :supported_staff, :hide_reports_tab, :static_locale, :preferred_mcc, :preferred_ministry

    has_many :default_map_views
    has_many :default_measurement_states
    attribute :content_locales

    def supported_staff
      user_preferences['supported_staff']
    end

    def hide_reports_tab
      user_preferences['hide_reports_tab']
    end

    def static_locale
      user_preferences['static_locale']
    end

    def preferred_mcc
      user_preferences['preferred_mcc']
    end

    def preferred_ministry
      user_preferences['preferred_ministry']
    end

    def content_locales
      locales = {}
      object.user_content_locales.each do |locale|
        locales[locale.ministry_id] = locale.locale
      end
      locales
    end

    def user_preferences
      return @preferences if @preferences
      preferences = {}
      object.user_preferences.each do |pref|
        preferences[pref.name] = pref.value
      end
      @preferences = preferences
    end

    def default_map_views
      map_views = []
      object.user_map_views.each do |view|
        data = {
          ministry_id: view.ministry_id,
          location: {
            latitude: view.lat,
            longitude: view.long
          },
          location_zoom: view.zoom
        }
        map_views << data
      end
      map_views
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
