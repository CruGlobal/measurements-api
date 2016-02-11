module Requests
  module AuthenticationHelpers
    def authenticated_user
      person = FactoryGirl.create(:person)
      access_token = CruLib::AccessToken.new(key_guid: person.cas_guid)
      return access_token.token, person
    end
  end
end
