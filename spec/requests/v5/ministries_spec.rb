require 'rails_helper'

RSpec.describe 'V5::Ministries', type: :request do
  describe 'GET /v5/ministries' do
    let!(:ministries) do
      ministries = []
      ministries << FactoryGirl.create(:ministry)
      ministries << FactoryGirl.create(:ministry)
      ministries << FactoryGirl.create(:ministry, parent_id: ministries.sample.id)
      ministries << FactoryGirl.create(:ministry, parent_id: ministries.sample.id)
      ministries
    end

    it 'responds with all ministries' do
      get '/v5/ministries', nil, 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"
      expect(response).to be_success
      json = JSON.parse(response.body)
      expect(json.length).to be ministries.length
    end

    context 'with refresh=true' do
      it 'responds with HTTP 202 Accepted' do
        clear_uniqueness_locks
        expect do
          get '/v5/ministries', { refresh: true }, 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"
          expect(response).to be_success
          expect(response).to have_http_status(202)
        end.to change(GlobalRegistry::SyncMinistriesWorker.jobs, :size).by(1)
      end
    end
  end

  describe 'GET /v5/ministries/:id' do
    let(:person) { FactoryGirl.create(:person) }
    let(:ministry) { FactoryGirl.create(:ministry) }

    context 'without an assignment' do
      it 'responds with HTTP 401' do
        get "/v5/ministries/#{ministry.gr_id}", nil, 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"
        expect(response).to have_http_status(401)
        json = JSON.parse(response.body)
        expect(json.keys).to contain_exactly('reason')
      end
    end

    context 'with an admin or leader assignment' do
      let!(:assignment) do
        FactoryGirl.create(:assignment, person_id: person.id, ministry_id: ministry.id,
                                        role: %i(admin leader inherited_admin inherited_leader).sample)
      end

      it 'responds with the ministry details' do
        get "/v5/ministries/#{ministry.gr_id}", nil,
            'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"

        expect(response).to be_success
        expect(response).to have_http_status(200)
        expect(response.body).to include_json(ministry_id: ministry.gr_id, min_code: ministry.min_code)
      end
    end

    context 'with a non admin/leader assignment' do
      let!(:assignment) do
        FactoryGirl.create(:assignment,
                           person_id: person.id,
                           ministry_id: ministry.id,
                           role: %i(blocked former_member self_assigned member).sample)
      end

      it 'responds with HTTP 401' do
        get "/v5/ministries/#{ministry.gr_id}", nil,
            'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"
        expect(response).to have_http_status(401)
        json = JSON.parse(response.body)
        expect(json.keys).to contain_exactly('reason')
      end
    end
  end

  # describe 'POST /v5/ministries' do
  #   context 'anyone can create a ministry' do
  #     let(:ministry) { FactoryGirl.build(:ministry) }
  #     before do
  #       gr_create_ministry_request(ministry)
  #     end
  #     it 'responds successfully with the new ministry' do
  #       expect do
  #         post '/v5/ministries', ministry.attributes, 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"
  #
  #         expect(response).to be_success
  #         json = JSON.parse(response.body).with_indifferent_access
  #         expect(json[:ministry_id]).to be_uuid
  #         expect(json[:team_members]).to be_an Array
  #
  #       end.to change { Ministry.count }.by(1).and(change {Assignments.count}.by(1))
  #     end
  #   end
  #
  #   context 'does not update existing ministries' do
  #
  #   end
  # end
end
