require 'rails_helper'

RSpec.describe 'V5::Ministries', type: :request do
  describe 'GET /v5/ministries' do
    let!(:ministries) do
      ministries = []
      ministries << FactoryGirl.create(:ministry)
      ministries << FactoryGirl.create(:ministry)
      ministries << FactoryGirl.create(:ministry)
      ministries << FactoryGirl.create(:ministry, parent_id: ministries.sample.id)
      ministries << FactoryGirl.create(:ministry, parent_id: ministries.sample.id)
      ministries << FactoryGirl.create(:ministry, parent_id: ministries.sample.id)
      ministries << FactoryGirl.create(:ministry, parent_id: ministries.sample.id)
      ministries << FactoryGirl.create(:ministry, parent_id: ministries.sample.id)
      ministries
    end

    it 'responds with all ministries' do
      get '/v5/ministries', nil, 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"
      json = JSON.parse(response.body)

      expect(response).to be_success
      expect(json.length).to be ministries.length
      ministry = json.sample
      expect(ministry.keys).to contain_exactly('ministry_id', 'name')
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
        expect(json).to contain_exactly('status', 'reason')
      end
    end

    context 'with an admin or leader assignment' do
      let!(:assignment) do
        FactoryGirl.create(:assignment,
                           person_id: person.id,
                           ministry_id: ministry.id,
                           role: %i(admin leader).sample)
      end

      it 'responds with the ministry details' do
        get "/v5/ministries/#{ministry.gr_id}", nil,
            'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"

        expect(response).to be_success
        expect(response).to have_http_status(200)
        expect(response.body).to include_json(ministry_id: ministry.gr_id,
                                              min_code: ministry.min_code,
                                              name: ministry.name,
                                              location_zoom: ministry.location_zoom,
                                              location: {
                                                # Conversion is lossy, compare lossy values
                                                latitude: ministry.latitude.to_json.to_f,
                                                longitude: ministry.longitude.to_json.to_f
                                              })
      end
    end

    context 'with an inherited admin/leader assignment' do
      let!(:assignment) do
        FactoryGirl.create(:assignment,
                           person_id: person.id,
                           ministry_id: ministry.id,
                           role: %i(admin leader).sample)
      end
      let(:sub_ministry) do
        FactoryGirl.create(:ministry, parent_id: ministry.id, latitude: nil, longitude: nil)
      end

      it 'responds with the ministry details' do
        get "/v5/ministries/#{sub_ministry.gr_id}", nil,
            'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"

        expect(response).to be_success
        expect(response).to have_http_status(200)
        expect(response.body).to include_json(ministry_id: sub_ministry.gr_id,
                                              min_code: sub_ministry.min_code,
                                              name: sub_ministry.name,
                                              location_zoom: sub_ministry.location_zoom,
                                              location: {
                                                # Ministry missing lat/lng should have parent values
                                                # Conversion is lossy, compare lossy values
                                                latitude: ministry.latitude.to_json.to_f,
                                                longitude: ministry.longitude.to_json.to_f
                                              })
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
        expect(json).to contain_exactly('status', 'reason')
      end
    end
  end
end
