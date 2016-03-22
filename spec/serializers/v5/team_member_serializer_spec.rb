# frozen_string_literal: true
require 'rails_helper'

RSpec.describe V5::TeamMemberSerializer do
  describe 'a ministry' do
    let(:ministry) { FactoryGirl.create(:ministry) }
    let(:assignment) { FactoryGirl.create(:assignment, ministry: ministry, person: person) }
    let(:serializer) { V5::TeamMemberSerializer.new(assignment) }
    let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
    let(:json) { serialization.as_json }

    describe 'a team member' do
      let(:person) { FactoryGirl.create(:person) }

      it 'has attributes' do
        expect(json[:person_id]).to be_uuid
        expect(json[:assignment_id]).to be_uuid
        expect(json[:team_role]).to_not be_nil
        expect(json[:first_name]).to_not be_nil
        expect(json[:last_name]).to_not be_nil
        expect(json[:key_username]).to_not be_nil
        expect(json[:key_guid]).to_not be_nil
      end
    end

    describe 'a team member missing key_username and key_guid' do
      let(:person) { FactoryGirl.create(:person, cas_username: nil, cas_guid: nil) }

      it 'does not include missing attributes' do
        expect(json.keys).to contain_exactly(:person_id, :assignment_id, :team_role, :first_name, :last_name)
      end
    end
  end
end
