require 'rails_helper'

RSpec.describe 'V5::MeasurementTypes', type: :request do
  let(:ministry) { FactoryGirl.create(:ministry) }

  describe 'GET /v5/sys_measurement_types' do
    let(:json) { JSON.parse(response.body) }
    let!(:measurement) { FactoryGirl.create(:measurement, english: 'English Name') }

    it 'responds with measurement types' do
      get '/v5/sys_measurement_types', access_token: authenticate_api, ministry_id: ministry.gr_id,
                                       locale: 'en'

      expect(response).to be_success
      expect(json.first['id']).to be measurement.id
      expect(json.first['localized_name']).to eq 'English Name'
    end

    context 'with bad authentication' do
      it 'fails when no token is sent' do
        get '/v5/sys_measurement_types'

        expect(response).to_not be_success
      end

      it 'fails when no token is sent' do
        WebMock.stub_request(:get, ENV['GLOBAL_REGISTRY_URL'] + 'systems?limit=1')
               .to_return(status: 400)

        random_token = SecureRandom.uuid
        get '/v5/sys_measurement_types', access_token: random_token
        expect(response).to_not be_success

        get '/v5/sys_measurement_types', {},
            'HTTP_AUTHORIZATION': "Bearer #{random_token}"
        expect(response).to_not be_success
      end
    end
  end

  describe 'GET /v5/sys_measurement_type/{id}' do
    let!(:measurement) { FactoryGirl.create(:measurement, perm_link: 'lmi_total_my_string') }
    let(:json) { JSON.parse(response.body) }

    it 'finds measurement based on total_id' do
      get "/v5/sys_measurement_type/#{measurement.total_id}", { ministry_id: ministry.gr_id },
          'HTTP_AUTHORIZATION': "Bearer #{authenticate_api}"

      expect(response).to be_success
      expect(json['id']).to be measurement.id
    end

    it 'finds measurement based on perm_link' do
      get '/v5/sys_measurement_type/my_string', { ministry_id: ministry.gr_id },
          'HTTP_AUTHORIZATION': "Bearer #{authenticate_api}"

      expect(json['id']).to be measurement.id
    end
  end
end
