require 'rails_helper'

RSpec.describe 'V5::MeasurementTypes', type: :request do
  let(:ministry) { FactoryGirl.create(:ministry) }

  describe 'GET /v5/sys_measurement_types' do
    let(:json) { JSON.parse(response.body) }
    let!(:measurement) { FactoryGirl.create(:measurement, english: 'English Name') }

    it 'responds with measurement types' do
      get '/v5/sys_measurement_types', { ministry_id: ministry.gr_id, locale: 'en' },
          'HTTP_AUTHORIZATION': "Bearer #{authenticate_api}"

      expect(response).to be_success
      expect(json.first['id']).to be measurement.id
      expect(json.first['localized_name']).to eq 'English Name'
    end
  end
end
