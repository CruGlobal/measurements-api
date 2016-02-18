require 'rails_helper'

RSpec.describe 'V5::Ministries', type: :request do
  describe 'GET /v5/ministries' do
    let!(:ministries) do
      ministries = []
      ministries << FactoryGirl.create(:ministry)
      ministries << FactoryGirl.create(:ministry)
      ministries << FactoryGirl.create(:ministry)
      ministries << FactoryGirl.create(:ministry, parent_id: ministries.sample.ministry_id)
      ministries << FactoryGirl.create(:ministry, parent_id: ministries.sample.ministry_id)
      ministries << FactoryGirl.create(:ministry, parent_id: ministries.sample.ministry_id)
      ministries << FactoryGirl.create(:ministry, parent_id: ministries.sample.ministry_id)
      ministries << FactoryGirl.create(:ministry, parent_id: ministries.sample.ministry_id)
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
end
