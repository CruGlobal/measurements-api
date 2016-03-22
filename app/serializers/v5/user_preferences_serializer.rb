# frozen_string_literal: true
module V5
  class UserPreferencesSerializer < ActiveModel::Serializer
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
        locales[locale.ministry.gr_id] = locale.locale
      end
      locales
    end

    def default_map_views
      object.user_map_views.map do |view|
        {
          ministry_id: view.ministry.gr_id,
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
      Ministry::MCCS.each do |mcc|
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
