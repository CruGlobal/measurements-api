require 'rails_helper'

RSpec.describe 'V5::Ministries', type: :request do
  describe 'GET /v5/ministries' do
    let!(:ministries) do
      ministries = []
      ministries << FactoryGirl.create(:ministry)
      ministries << FactoryGirl.create(:ministry)
      ministries << FactoryGirl.create(:ministry)
      ministries << FactoryGirl.create(:ministry, parent_id: ministries.sample.ministry_id)
      ministries
    end

    it 'responds with all ministries' do
      token, _person = authenticated_user
      get '/v5/ministries', nil, {'HTTP_AUTHORIZATION': "Bearer #{token}"}
      json = JSON.parse(response.body)

      expect(response).to be_success
      expect(json.length).to be ministries.length
    end
  end
end
