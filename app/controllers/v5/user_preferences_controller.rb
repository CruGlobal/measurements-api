module V5
  class UserPreferencesController < V5::BaseController
    include V5::AccessTokenProtectedConcern

    before_action :authenticate_request

    def index
      person = Person.find_or_initialize(@access_token.key_guid)
      api_error('Invalid User') unless person
      presenter = UserPreferencesPresenter.new(person)
      api_error('Error') unless presenter
      render json: presenter
    end

    def create
      @person = Person.find_or_initialize(@access_token.key_guid)
      api_error('Invalid User') unless @person
      update_preferences(request.request_parameters)
      presenter = UserPreferencesPresenter.new(@person)
      api_error('Error') unless presenter
      render json: presenter
    end

    private

    def update_preferences(preferences = {})
      preferences.each do |key, value|
        if key == 'default_map_views'
          update_default_map_views(value)
        elsif key == 'default_measurement_states'
          update_default_measurement_states(value)
        elsif key == 'content_locales'
          update_default_content_locales(value)
        else
          update_user_preference(key, value)
        end
      end
    end

    def update_user_preference(name, value)
      user_pref = @person.user_preferences.where(name: name).first
      if value.nil?
        @person.user_preferences.destroy(user_pref) if user_pref
      else
        user_pref ||= @person.user_preferences.build(name: name)
        user_pref.attributes = { value: value }
        user_pref.save
      end
    end

    def update_default_map_views(value)
      if value.nil?
        @person.user_map_views.clear
      else
        value.each do |view|
          update_default_map_view(view)
        end
      end
    end

    def update_default_map_view(view)
      map_view = @person.user_map_views.where(ministry_id: view['ministry_id']).first
      map_view ||= @person.user_map_views.build(ministry_id: view['ministry_id'])
      map_view.attributes = {
        lat: view['location']['latitude'],
        long: view['location']['longitude'],
        zoom: view['location_zoom']
      }
      map_view.save
    end

    def update_default_measurement_states(value)
      if value.nil?
        @person.user_measurement_states.clear
      else
        value.each do |mcc, perm_link_stubs|
          perm_link_stubs.each do |perm_link_stub, visible|
            state = @person.user_measurement_states.where(mcc: mcc, perm_link_stub: perm_link_stub).first
            state ||= @person.user_measurement_states.build(mcc: mcc, perm_link_stub: perm_link_stub)
            state.attributes = { visible: visible == 1 }
            state.save
          end
        end
      end
    end

    def update_default_content_locales(value)
      if value.nil?
        @person.user_content_locales.clear
      else
        content_locales = []
        value.each do |ministry_id, locale|
          content_locale = @person.user_content_locales.where(ministry_id: ministry_id).first
          content_locale ||= @person.user_content_locales.build(ministry_id: ministry_id)
          content_locale.attributes = { locale: locale }
          content_locales << content_locale
        end
        @person.user_content_locales = content_locales
      end
    end
  end
end
