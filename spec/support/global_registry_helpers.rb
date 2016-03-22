# frozen_string_literal: true
module GlobalRegistryHelpers
  def gr_person_request_by_username(person = nil)
    person ||= FactoryGirl.create(:person)
    response = { person: { id: person.gr_id, last_name: person.last_name, first_name: person.first_name,
                           key_username: person.cas_username, client_integration_id: person.cas_guid,
                           authentication: { id: SecureRandom.uuid, key_guid: person.cas_guid } } }
    WebMock
      .stub_request(:get, "#{ENV['GLOBAL_REGISTRY_URL']}/entities")
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
      .stub_request(:get, "#{ENV['GLOBAL_REGISTRY_URL']}/entities")
      .with(query: { entity_type: 'person',
                     fields: 'first_name,last_name,key_username,authentication.key_guid',
                     'filters[authentication][key_guid]': person.cas_guid })
      .to_return(status: 200, body: { entities: [response] }.to_json, headers: {})
  end

  def gr_get_invalid_ministry_request(ministry)
    ministry ||= FactoryGirl.build(:ministry)
    response = { error: 'We couldn\'t find the record you were looking for.' }
    WebMock
      .stub_request(:get, "#{ENV['GLOBAL_REGISTRY_URL']}/entities/#{ministry.gr_id}")
      .to_return(status: 404, body: response.to_json, headers: {})
  end

  def gr_create_ministry_request(ministry = nil)
    ministry ||= FactoryGirl.create(:ministry)
    response = { ministry: { id: ministry.gr_id, client_integration_id: ministry.min_code } }
    WebMock
      .stub_request(:post, "#{ENV['GLOBAL_REGISTRY_URL']}/entities")
      .to_return(status: 201, body: { entity: response }.to_json, headers: {})
  end

  def gr_create_assignment_request(assignment)
    response = { person: {
      id: assignment.person.gr_id,
      'ministry:relationship' => [{ ministry: assignment.ministry.gr_id,
                                    relationship_entity_id: assignment.gr_id || SecureRandom.uuid,
                                    client_integration_id: "_#{assignment.person.gr_id}_#{assignment.ministry.gr_id}",
                                    team_role: assignment.role
                                  }] } }

    # We need to always create assignments using the root GLOBAL_REGISTRY_TOKEN
    # keey and not a system key to prevent a system from gaining
    # higher-than-planned access to the measurements api data.
    WebMock
      .stub_request(:put, "#{ENV['GLOBAL_REGISTRY_URL']}/entities/#{assignment.person.gr_id}")
      .with(query: { fields: 'ministry:relationship', full_response: 'true' },
            headers: { 'Authorization' => "Bearer #{ENV['GLOBAL_REGISTRY_TOKEN']}" })
      .to_return(status: 200, body: { entity: response }.to_json, headers: {})
  end

  def gr_update_assignment_request(assignment)
    WebMock
      .stub_request(:put, "#{ENV['GLOBAL_REGISTRY_URL']}/entities/#{assignment.gr_id}")
      .with(headers: { 'Authorization' => "Bearer #{ENV['GLOBAL_REGISTRY_TOKEN']}" })
      .to_return(status: 200, body: { entity: {} }.to_json, headers: {})
  end
end
