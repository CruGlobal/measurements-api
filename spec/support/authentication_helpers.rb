module AuthenticationHelpers
  def authenticate_person(person = nil)
    person = FactoryGirl.create(:person) if person.nil?
    access_token = CruLib::AccessToken.new(key_guid: person.cas_guid)
    access_token.token
  end
end
