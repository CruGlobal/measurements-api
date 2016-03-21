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
      WebMock.stub_request(:get, "#{ENV['GLOBAL_REGISTRY_URL']}/measurement_types/#{meas.send(key)}")
             .with(query: hash_including)
             .to_return(body: measurement_json.to_json)
    end
  end

  describe 'POST /v5/measurements' do
    let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: 7) }
    let(:measurement) { FactoryGirl.create(:measurement) }

    it 'responds with measurement breakdowns' do
      measurements_body = [{ measurement_type_id: measurement.local_id, source: 'gma-app',
                             value: 123, ministry_id: ministry.gr_id, mcc: 'gcm' },
                           { measurement_type_id: measurement.local_id, source: 'churches',
                             value: 123, ministry_id: ministry.gr_id, mcc: 'gcm' },
                           { measurement_type_id: measurement.person_id, source: 'churches',
                             value: 123, assignment_id: assignment.gr_id, mcc: 'gcm' }]
      post_gr_stub = WebMock.stub_request(:post, "#{ENV['GLOBAL_REGISTRY_URL']}/measurements")
      allow_any_instance_of(Measurement::MeasurementRollup).to receive(:run)

      post '/v5/sys_measurements/', { _json: measurements_body },
           'HTTP_AUTHORIZATION': "Bearer #{authenticate_api}"

      expect(response.code.to_i).to be 201
      expect(post_gr_stub).to have_been_requested.times(3)
    end
  end
end
