module V5
  class TokenAndUserSerializer < ActiveModel::Serializer
    attributes :status, :session_ticket

    has_one :user
    has_one :user_preferences, serializer: UserPreferencesSerializer

    has_many :assignments

    def user
      {
        first_name: object.access_token.first_name,
        last_name: object.access_token.last_name,
        cas_username: object.access_token.email,
        person_id: object.access_token.guid
      }
    end

    def user_preferences
      object.person
    end
  end
end
