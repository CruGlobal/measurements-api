module GlobalRegistryHelpers
  def gr_person_request_by_username(person = nil)
    person ||= FactoryGirl.create(:person)
    response = { person: { id: person.person_id, last_name: person.last_name, first_name: person.first_name,
                           key_username: person.cas_username, client_integration_id: person.cas_guid,
                           authentication: { id: SecureRandom.uuid, key_guid: person.cas_guid } } }
    WebMock
      .stub_request(:get, "#{ENV['GLOBAL_REGISTRY_URL']}entities")
      .with(query: { entity_type: 'person',
                     fields: 'first_name,last_name,key_username,authentication.key_guid',
                     'filters[key_username]': person.cas_username })
      .to_return(status: 200, body: { entities: [response] }.to_json, headers: {})
  end

  def gr_person_request_by_guid(person = nil)
    person ||= FactoryGirl.create(:person)
    response = { person: { id: person.gr_id, last_name: person.last_name, first_name: person.first_name,
                           key_username: person.cas_username, client_integration_id: person.cas_guid,
                           authentication: { id: SecureRandom.uuid, key_guid: person.cas_guid } } }
    WebMock
      .stub_request(:get, "#{ENV['GLOBAL_REGISTRY_URL']}entities")
      .with(query: { entity_type: 'person',
                     fields: 'first_name,last_name,key_username,authentication.key_guid',
                     'filters[authentication][key_guid]': person.cas_guid })
      .to_return(status: 200, body: { entities: [response] }.to_json, headers: {})
  end
end
