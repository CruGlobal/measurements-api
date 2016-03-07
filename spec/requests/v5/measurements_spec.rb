require 'rails_helper'

RSpec.describe 'V5::Measurements', type: :request do
  let(:ministry) { FactoryGirl.create(:ministry) }
  let(:user) { FactoryGirl.create(:person) }
  let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: 7) }

  describe 'GET /v5/measurements' do
    def measurement_json
      {
        measurement_type: {
          perm_link: 'LMI',
          measurements: [
            {
              id: SecureRandom.uuid,
              period: '2015-04',
              value: '4.0'
            }
          ]
        }
      }
    end

    def stub_gr_measurement_calls(meas)
      %w(total_id local_id person_id).each do |key|
        WebMock.stub_request(:get, "#{ENV['GLOBAL_REGISTRY_URL']}measurement_types/#{meas.send(key)}")
               .with(query: hash_including)
               .to_return(body: measurement_json.to_json)
      end
    end

    let(:json) { JSON.parse(response.body) }
    let!(:measurement) { FactoryGirl.create(:measurement, english: 'English Name') }

    it 'responds with measurements' do
      stub_gr_measurement_calls(measurement)

      get '/v5/measurements', { ministry_id: ministry.gr_id, mcc: 'SLM' },
          'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

      expect(response).to be_success
      expect(json.first['name']).to eq 'English Name'
    end
  end
end
