module V5
  class UserPreferencesPresenter < V5::BasePresenter

    def initialize(person)
      @person = person
    end

    def as_json(options={})
      data = user_preferences
      data['default_map_views'] = user_map_views unless @person.user_map_views.empty?
      data['default_measurement_states'] = user_measurement_states unless @person.user_measurement_states.empty?
      data['content_locales'] = user_content_locales unless @person.user_content_locales.empty?
      data
    end

    private

    def user_preferences
      preferences = {}
      @person.user_preferences.each do |pref|
        preferences[pref.name] = pref.value
      end
      preferences
    end

    def user_map_views
      map_views = []
      @person.user_map_views.each do |view|
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

    def user_measurement_states
      states = {}
      Constants::MCCS.each do |mcc|
        mcc_data = {}
        @person.user_measurement_states.where(mcc: mcc).each do |state|
          mcc_data[state.perm_link_stub] = state.visible ? 1 : 0
        end
        states[mcc] = mcc_data
      end
      states
    end

    def user_content_locales
      locales = {}
      @person.user_content_locales.each do |locale|
        locales[locale.ministry_id] = locale.locale
      end
      locales
    end
  end
end
