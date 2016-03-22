# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'V5::SystemsAssignments', type: :request do
  let(:ministry) { FactoryGirl.create(:ministry) }
  let(:json) { JSON.parse(response.body) }
  let(:gr_access_toke) { authenticate_api }

  describe 'POST /v5/assignments' do
    let(:person) { FactoryGirl.build(:person) }
    context 'new assignment by username' do
      let(:assignment) { FactoryGirl.build(:assignment, ministry: ministry, person: person, role: :admin) }
      let!(:person_request) { gr_person_request_by_username(person) }
      let!(:assignment_request) { gr_create_assignment_request(assignment) }

      it 'responds successfully with an assignment' do
        post '/v5/sys_assignments',
             { username: person.cas_username, ministry_id: ministry.gr_id, team_role: 'admin' },
             'HTTP_AUTHORIZATION': "Bearer #{gr_access_toke}"

        expect(response).to be_success
        expect(response).to have_http_status 201
        expect(person_request).to have_been_requested
        expect(assignment_request).to have_been_requested
        expect(json).to include('team_role' => 'admin').and(include('id'))
        expect(json['id']).to be_uuid
      end
    end

    context 'new assignment by key_guid' do
      let(:assignment) { FactoryGirl.build(:assignment, ministry: ministry, person: person, role: :member) }
      let!(:person_request) { gr_person_request_by_guid(person) }
      let!(:assignment_request) { gr_create_assignment_request(assignment) }

      it 'responds successfully with an assignment' do
        post '/v5/sys_assignments',
             { key_guid: person.cas_guid, ministry_id: ministry.gr_id, team_role: 'member' },
             'HTTP_AUTHORIZATION': "Bearer #{gr_access_toke}"

        expect(response).to be_success
        expect(response).to have_http_status 201
        expect(person_request).to have_been_requested
        expect(assignment_request).to have_been_requested
        expect(json).to include('team_role' => 'member').and(include('id'))
        expect(json['id']).to be_uuid
      end
    end

    context 'new assignment by person_id' do
      let(:leader) { FactoryGirl.create(:person) }
      let(:assignment) { FactoryGirl.build(:assignment, ministry: ministry, person: leader, role: :leader) }
      let!(:assignment_request) { gr_create_assignment_request(assignment) }

      it 'responds successfully with an assignment' do
        post '/v5/sys_assignments',
             { person_id: leader.gr_id, ministry_id: ministry.gr_id, team_role: 'leader' },
             'HTTP_AUTHORIZATION': "Bearer #{gr_access_toke}"

        expect(response).to be_success
        expect(response).to have_http_status 201
        expect(assignment_request).to have_been_requested
        expect(json).to include('team_role' => 'leader').and(include('id'))
        expect(json['id']).to be_uuid
      end
    end
  end

  describe 'PUT /v5/assignments/:id' do
    let(:person) { FactoryGirl.create(:person) }
    let(:assignment) do
      FactoryGirl.create(:assignment, ministry: ministry, person: person, role: :member, gr_id: SecureRandom.uuid)
    end
    context 'update an assignment' do
      let!(:assignment_request) { gr_update_assignment_request(assignment) }
      it 'responds successfully with updated assignment' do
        put "/v5/sys_assignments/#{assignment.gr_id}", { team_role: 'leader' },
            'HTTP_AUTHORIZATION': "Bearer #{gr_access_toke}"

        expect(response).to be_success
        expect(response).to have_http_status 200
        expect(assignment_request).to have_been_requested
        expect(json).to include('team_role' => 'leader').and(include('id'))
        expect(json['id']).to be_uuid
      end
    end
  end
end
