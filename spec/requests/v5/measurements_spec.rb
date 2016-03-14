require 'rails_helper'

RSpec.describe 'V5::Measurements', type: :request do
  let(:ministry) { FactoryGirl.create(:ministry) }
  let(:user) { FactoryGirl.create(:person) }
  let(:json) { JSON.parse(response.body) }

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

  describe 'GET /v5/measurements' do
    let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :admin) }
    let!(:measurement) { FactoryGirl.create(:measurement, english: 'English Name') }

    it 'responds with measurements' do
      stub_gr_measurement_calls(measurement)

      get '/v5/measurements', { ministry_id: ministry.gr_id, mcc: 'SLM' },
          'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

      expect(response).to be_success
      expect(json.first['name']).to eq 'English Name'
    end
  end

  describe 'GET /v5/measurements/:id' do
    let(:measurement) { FactoryGirl.create(:measurement, english: 'English Name') }

    context 'as admin' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :admin) }

      it 'responds with measurement breakdowns' do
        stub_gr_measurement_calls(measurement)

        get "/v5/measurements/#{measurement.total_id}", { ministry_id: ministry.gr_id, mcc: 'SLM' },
            'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

        expect(response).to be_success
        expect(json['local_breakdown']).to be_a Hash
      end
    end

    context 'as self-assigned' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :self_assigned) }

      it 'responds with 401' do
        get "/v5/measurements/#{measurement.total_id}", { ministry_id: ministry.gr_id, mcc: 'SLM' },
            'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

        expect(response.code.to_i).to eq 401
      end
    end
  end
end
