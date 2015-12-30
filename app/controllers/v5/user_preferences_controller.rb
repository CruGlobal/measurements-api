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
        case key
        when UserPreferencesPresenter::PROPERTY_MAP_VIEWS
          @person.add_or_update_map_views(value)
        when UserPreferencesPresenter::PROPERTY_MEASUREMENT_STATES
          @person.add_or_update_measurement_states(value)
        when UserPreferencesPresenter::PROPERTY_CONTENT_LOCALES
          @person.add_or_update_content_locales(value)
        else
          @person.add_or_update_preference(key, value)
        end
      end
    end
  end
end
