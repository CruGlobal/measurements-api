# frozen_string_literal: true

require "rails_helper"

RSpec.describe "V5::Measurements", type: :request do
  let(:ministry) { FactoryGirl.create(:ministry) }
  let(:user) { FactoryGirl.create(:person) }
  let(:json) { JSON.parse(response.body) }

  def measurement_json
    {
      measurement_type: {
        perm_link: "LMI",
        measurements: [
          {
            id: SecureRandom.uuid,
            period: "2015-04",
            value: "4.0",
          },
        ],
      },
    }
  end

  def stub_gr_measurement_calls(meas)
    %w[total_id local_id person_id].each do |key|
      WebMock.stub_request(:get, "#{ENV["GLOBAL_REGISTRY_URL"]}/measurement_types/#{meas.send(key)}")
        .with(query: hash_including)
        .to_return(body: measurement_json.to_json)
    end
  end

  describe "POST /v5/measurements" do
    let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: 7) }
    let(:measurement) { FactoryGirl.create(:measurement) }

    it "responds with measurement breakdowns" do
      clear_uniqueness_locks
      measurements_body = [{measurement_type_id: measurement.local_id, source: "gma-app",
                            value: 123, ministry_id: ministry.gr_id, mcc: "gcm",},
                           {measurement_type_id: measurement.local_id, source: "churches",
                            value: 123, ministry_id: ministry.gr_id, mcc: "gcm",},
                           {measurement_type_id: measurement.person_id, source: "churches",
                            value: 123, assignment_id: assignment.gr_id, mcc: "gcm",},]

      expect {
        post "/v5/sys_measurements/", params: {_json: measurements_body},
                                      headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_api}"}
        expect(response).to be_successful
        expect(response).to have_http_status(201)
      }.to change(GrSync::WithGrWorker.jobs, :size).by(3)
    end
  end
end
