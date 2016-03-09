module V5
  class UserPreferencesController < V5::BaseUserController
    def index
      load_person or render_not_found
      render_preferences
    end

    def create
      load_person or render_not_found
      update_preferences
      render_preferences
    end

    private

    def load_person
      @person ||= ::Person::UpdatePreferences.find(current_user.id)
    end

    def render_preferences
      render json: @person, serializer: UserPreferencesSerializer if @person
    end

    def update_preferences
      @person.update_preferences(post_params)
    end
  end
end
