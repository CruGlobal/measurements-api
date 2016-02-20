require 'rails_helper'

RSpec.describe 'V5::Churches', type: :request do
  let(:ministry) { FactoryGirl.create(:ministry) }
  let(:user) { FactoryGirl.create(:person) }

  describe 'GET /v5/trainings' do
    let!(:training) { FactoryGirl.create(:training, ministry: ministry) }
    let(:json) { JSON.parse(response.body) }

    it 'responds with trainings' do
      get '/v5/trainings', { ministry_id: ministry.gr_id },
          'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"

      expect(response).to be_success
      expect(json.first['id']).to be training.id
    end
  end

  describe 'POST /v5/trainings' do
  end

  describe 'PUT /v5/trainings/:id' do
  end
end
