require 'rails_helper'

RSpec.describe 'V5::MeasurementTypes', type: :request do
  let(:ministry) { FactoryGirl.create(:ministry) }
  let(:user) { FactoryGirl.create(:person) }
  let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: 7) }

  describe 'GET /v5/measurement_type' do
    let!(:measurement) { FactoryGirl.create(:measurement) }
    let(:json) { JSON.parse(response.body) }

    it 'responds with measurement types' do
      get '/v5/measurement_types', { ministry_id: ministry.gr_id, locale: 'en' },
          'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

      expect(response).to be_success
      expect(json.first['id']).to be measurement.id
    end
  end
end
