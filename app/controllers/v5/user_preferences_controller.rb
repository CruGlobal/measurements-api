module V5
  class UserPreferencesController < V5::BaseUserController
    def index
      person = Person.find_or_initialize(@access_token.key_guid)
      api_error('Invalid User') unless person
      render json: @person, serializer: UserPreferencesSerializer
    end

    def create
      @person = Person.find_or_initialize(@access_token.key_guid)
      api_error('Invalid User') unless @person
      update_preferences(request.request_parameters)
      render json: @person, serializer: UserPreferencesSerializer
    end

    private

    def update_preferences(preferences = {})
      preferences.each do |key, value|
        case key
        when UserPreferencesSerializer::PROPERTY_MAP_VIEWS
          @person.add_or_update_map_views(value)
        when UserPreferencesSerializer::PROPERTY_MEASUREMENT_STATES
          @person.add_or_update_measurement_states(value)
        when UserPreferencesSerializer::PROPERTY_CONTENT_LOCALES
          @person.add_or_update_content_locales(value)
        else
          @person.add_or_update_preference(key, value)
        end
      end
    end
  end
end
