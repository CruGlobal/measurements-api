# frozen_string_literal: true
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

  describe 'GET /v5/measurements' do
    let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :admin) }
    let!(:measurement) { FactoryGirl.create(:measurement, english: 'English Name', perm_link: 'lmi_total_test') }

    it 'responds with measurements' do
      stub_gr_measurement_calls(measurement)

      get '/v5/measurements', params: { ministry_id: ministry.gr_id, mcc: 'SLM' },
                              headers: { 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}" }

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

        get "/v5/measurements/#{measurement.total_id}",
            params: { ministry_id: ministry.gr_id, mcc: 'SLM' },
            headers: { 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}" }

        expect(response).to be_success
        expect(json['local_breakdown']).to be_a Hash
      end

      context 'with invalid id' do
        it 'response with 404' do
          get '/v5/measurements/missing_perm_link',
              params: { ministry_id: ministry.gr_id, mcc: 'SLM' },
              headers: { 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}" }

          expect(response.code.to_i).to eq 404
        end
      end
    end

    context 'as self-assigned' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :self_assigned) }

      it 'responds with 401' do
        get "/v5/measurements/#{measurement.total_id}",
            params: { ministry_id: ministry.gr_id, mcc: 'SLM' },
            headers: { 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}" }

        expect(response.code.to_i).to eq 401
      end
    end
  end

  describe 'POST /v5/measurements' do
    let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: 7) }
    let(:measurement) { FactoryGirl.create(:measurement) }

    context 'as admin' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :admin) }

      it 'responds with created' do
        clear_uniqueness_locks
        measurements_body = [{ measurement_type_id: measurement.local_id, source: 'gma-app',
                               value: 123, ministry_id: ministry.gr_id, mcc: 'gcm' },
                             { measurement_type_id: measurement.local_id, source: 'churches',
                               value: 123, ministry_id: ministry.gr_id, mcc: 'gcm' }]

        expect do
          post '/v5/measurements/', params: { _json: measurements_body },
                                    headers: { 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}" }
          expect(response).to be_success
          expect(response).to have_http_status(201)
        end.to change(GrSync::WithGrWorker.jobs, :size).by(2)
      end
    end
  end
end
