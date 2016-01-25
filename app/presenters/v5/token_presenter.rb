module V5
  class TokenPresenter < V5::BasePresenter
    def initialize(access_token, person)
      @access_token = access_token
      @person = person
    end

    def as_json(_options = {})
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
  end
end
