module V5
  class TokenAndUserSerializer < ActiveModel::Serializer
    attributes :status, :session_ticket

    has_one :user

    has_many :assignments

    def _as_json(_options = {})
      {
        status: 'success',
        session_ticket: @access_token.attributes[:token],
        assignments: [],
        user: {
          first_name: @access_token.first_name,
          last_name: @access_token.last_name,
          cas_username: @access_token.email,
          person_id: @person.person_id
        },
        user_preferences: UserPreferencesPresenter.new(@person).as_json
      }
    end

    def user
      {
        first_name: object.access_token.first_name,
        last_name: object.access_token.last_name,
        cas_username: object.access_token.email,
        person_id: object.access_token.guid
      }
    end
  end
end
