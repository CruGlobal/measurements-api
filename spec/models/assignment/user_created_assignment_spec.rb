# frozen_string_literal: true
require 'rails_helper'

describe Assignment::UserCreatedAssignment do
  it 'looks up person by ea_guid if specified' do
    ea_guid = SecureRandom.uuid
    ministry = create(:ministry)
    person = build(:person, ea_guid: ea_guid)
    allow(Person).to receive(:person_for_ea_guid) { person }
    stub_request(:put, %r{#{ENV['GLOBAL_REGISTRY_URL']}/.*}).to_return(body: {
      entity: { person: { 'ministry:relationship': [{
        ministry: ministry.gr_id,
        relationship_entity_id: SecureRandom.uuid
      }] } }
    }.to_json)
    assignment = Assignment::UserCreatedAssignment.new(ministry: ministry,
                                                       ea_guid: ea_guid)

    expect(assignment.save).to be true
    expect(assignment.person).to eq person
  end
end
