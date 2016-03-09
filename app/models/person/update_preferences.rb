class Person
  class UpdatePreferences < ::Person
    def update_preferences(preferences = {})
      preferences.each do |key, value|
        case key
        when 'default_map_views'
          add_or_update_map_views(value)
        when 'default_measurement_states'
          add_or_update_measurement_states(value)
        when 'content_locales'
          add_or_update_content_locales(value)
        else
          add_or_update_preference(key, value)
        end
      end
    end

    private

    def add_or_update_preference(name, value)
      # Creates or updates a user_preference, deletes if value is nil
      pref = user_preferences.find_by(name: name) # where(name: name).first
      if value.nil?
        user_preferences.destroy(pref) if pref
      else
        pref ||= user_preferences.build(name: name)
        pref.attributes = { value: value }
        pref.save
      end
    end

    def add_or_update_map_views(value)
      user_map_views.clear and return if value.nil?
      value.each do |view|
        ministry = ministry_param(view['ministry_id'])
        next unless ministry
        map_view = user_map_views.find_by ministry_id: ministry.id
        map_view ||= user_map_views.build ministry_id: ministry.id
        map_view.attributes = {
          lat: view['location']['latitude'],
          long: view['location']['longitude'],
          zoom: view['location_zoom']
        }
        map_view.save
      end
    end

    def add_or_update_measurement_states(value)
      user_measurement_states.clear and return if value.nil?
      value.each do |mcc, perm_link_stubs|
        perm_link_stubs.each do |perm_link_stub, visible|
          state = user_measurement_states.find_by(mcc: mcc, perm_link_stub: perm_link_stub)
          state ||= user_measurement_states.build(mcc: mcc, perm_link_stub: perm_link_stub)
          state.attributes = { visible: visible == 1 }
          state.save
        end
      end
    end

    def add_or_update_content_locales(value)
      user_content_locales.clear and return if value.nil?
      content_locales = []
      value.each do |gr_id, locale|
        ministry = ministry_param(gr_id)
        next unless ministry
        content_locale = user_content_locales.find_by(ministry_id: ministry.id)
        content_locale ||= user_content_locales.build(ministry: ministry)
        content_locale.attributes = { locale: locale }
        content_locales << content_locale
      end
      self.user_content_locales = content_locales
    end
  end
end
