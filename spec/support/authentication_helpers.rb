module AuthenticationHelpers
  def authenticate_person(person = nil)
    person = FactoryGirl.create(:person) if person.nil?
    access_token = CruLib::AccessToken.new(key_guid: person.cas_guid)
    access_token.token
  end

  def authenticate_api
    token = SecureRandom.uuid.delete('-')

    WebMock.stub_request(:get, ENV['GLOBAL_REGISTRY_URL'] + 'systems?limit=1')
           .with(headers: { 'Authorization' => "Bearer #{token}" })
           .to_return(status: 200, body: { access: 'granted' }.to_json)

    token
  end
end
