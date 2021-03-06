# frozen_string_literal: true

require "rails_helper"

RSpec.describe "V5::SystemsMeasurementTypes", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:ministry) { FactoryBot.create(:ministry) }

  describe "GET /v5/sys_measurement_types" do
    let(:json) { JSON.parse(response.body) }
    let!(:measurement) { FactoryBot.create(:measurement, english: "English Name") }

    it "responds with measurement types" do
      get "/v5/sys_measurement_types", params: {access_token: authenticate_api, ministry_id: ministry.gr_id,
                                                locale: "en",}

      expect(response).to be_successful
      expect(json.first["id"]).to be measurement.id
      expect(json.first["localized_name"]).to eq "English Name"
    end

    it "caches authentication" do
      token = CruAuthLib::AccessToken.new.token

      gr_request = WebMock.stub_request(:get, ENV["GLOBAL_REGISTRY_BACKEND_URL"] + "/systems?limit=1")
        .with(headers: {"Authorization" => "Bearer #{token}"})
        .to_return(status: 200, body: {access: "granted"}.to_json)

      get "/v5/sys_measurement_types", params: {access_token: token}
      travel_to 5.minutes.from_now do
        get "/v5/sys_measurement_types", params: {access_token: token}
      end
      expect(gr_request).to have_been_requested
    end

    it "reauthenticates authentication after expire" do
      token = CruAuthLib::AccessToken.new.token

      gr_request = WebMock.stub_request(:get, ENV["GLOBAL_REGISTRY_BACKEND_URL"] + "/systems?limit=1")
        .with(headers: {"Authorization" => "Bearer #{token}"})
        .to_return(status: 200, body: {access: "granted"}.to_json)

      get "/v5/sys_measurement_types", params: {access_token: token}
      travel_to 2.days.from_now do
        get "/v5/sys_measurement_types", params: {access_token: token}
      end
      expect(gr_request).to have_been_requested.times(2)
    end

    context "with bad authentication" do
      it "fails when no token is sent" do
        get "/v5/sys_measurement_types"

        expect(response).to_not be_successful
      end

      it "fails when no token is sent" do
        WebMock.stub_request(:get, ENV["GLOBAL_REGISTRY_BACKEND_URL"] + "/systems?limit=1")
          .to_return(status: 400)

        random_token = SecureRandom.uuid
        get "/v5/sys_measurement_types", params: {access_token: random_token}
        expect(response).to_not be_successful

        get "/v5/sys_measurement_types",
          headers: {'HTTP_AUTHORIZATION': "Bearer #{random_token}"}
        expect(response).to_not be_successful
      end
    end
  end

  describe "GET /v5/sys_measurement_type/{id}" do
    let!(:measurement) { FactoryBot.create(:measurement, perm_link: "lmi_total_my_string") }
    let(:json) { JSON.parse(response.body) }

    it "finds measurement based on total_id" do
      get "/v5/sys_measurement_type/#{measurement.total_id}",
        params: {ministry_id: ministry.gr_id},
        headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_api}"}

      expect(response).to be_successful
      expect(json["id"]).to be measurement.id
    end

    it "finds measurement based on perm_link" do
      get "/v5/sys_measurement_type/my_string", params: {ministry_id: ministry.gr_id},
                                                headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_api}"}

      expect(json["id"]).to be measurement.id
    end
  end

  describe "POST /v5/sys_measurement_types" do
    let(:json) { JSON.parse(response.body) }

    let(:attributes) do
      {
        perm_link_stub: "reporting",
        english: "Number of Non-Staff Reporting",
        description: "Number of Non-Staff Reporting",
        localized_name: "Présenter le Saint-Esprit",
        localized_description: "Nombre de personnes avec lesquelles le ministère de l'Esprit Saint",
        section: "other",
        column: "other",
        sort_order: 99,
        ministry_id: ministry.gr_id,
        locale: "fr",
      }
    end

    let(:token) { authenticate_api }

    before do
      @gr_meas_type_request = WebMock.stub_request(:post, "#{ENV["GLOBAL_REGISTRY_URL"]}/measurement_types")
        .with(headers: {'Authorization': "Bearer #{token}"})
        .to_return(body: {measurement_type: {id: SecureRandom.uuid}}.to_json)
    end

    it "creates a measurement type" do
      expect {
        post "/v5/sys_measurement_types", params: attributes, headers: {'HTTP_AUTHORIZATION': "Bearer #{token}"}
      }.to change(Measurement, :count).by(1).and(change(MeasurementTranslation, :count).by(1))

      expect(response.code.to_i).to be 201
      expect(json["id"]).to_not be_nil

      expect(Measurement.last.english).to eq "Number of Non-Staff Reporting"
      expect(Measurement.last.perm_link).to eq "lmi_total_custom_reporting"

      expect(MeasurementTranslation.last.name).to eq "Présenter le Saint-Esprit"

      # expect that we used the users token for the GR request
      expect(@gr_meas_type_request).to have_been_requested.times(3)
    end

    it "creates a core measurement type" do
      expect {
        post "/v5/sys_measurement_types", params: attributes.merge(is_core: "1"),
                                          headers: {'HTTP_AUTHORIZATION': "Bearer #{token}"}
      }.to change(Measurement, :count).by(1)

      expect(response.code.to_i).to be 201

      expect(Measurement.last.perm_link).to eq "lmi_total_reporting"
    end
  end

  describe "PUT /v5/sys_measurement_type/:id" do
    let(:json) { JSON.parse(response.body) }
    let(:measurement) { FactoryBot.create(:measurement) }
    let(:parent_meas) { FactoryBot.create(:measurement) }

    let(:attributes) { {english: "different name", parent_id: parent_meas.total_id, sort_order: 10} }

    it "updates measurement type without locale params" do
      put "/v5/sys_measurement_types/#{measurement.total_id}",
        params: attributes,
        headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_api}"}

      expect(response.code.to_i).to be 200
      # expect that the object was rendered on the way back
      expect(json["id"]).to be measurement.id
      measurement.reload
      expect(measurement.english).to eq "different name"
      expect(measurement.parent.id).to eq parent_meas.id
      expect(measurement.sort_order).to be 10
    end
  end
end
