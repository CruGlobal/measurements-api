# frozen_string_literal: true

require "rails_helper"

RSpec.describe "V5::MeasurementTypes", type: :request do
  let(:ministry) { FactoryGirl.create(:ministry) }
  let(:user) { FactoryGirl.create(:person) }
  let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: 7) }

  describe "GET /v5/measurement_types" do
    let(:json) { JSON.parse(response.body) }
    let!(:measurement) { FactoryGirl.create(:measurement, english: "English Name") }

    it "responds with measurement types" do
      get "/v5/measurement_types", params: {ministry_id: ministry.gr_id, locale: "en"},
                                   headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"}

      expect(response).to be_successful
      expect(json.first["id"]).to be measurement.id
      expect(json.first["localized_name"]).to eq "English Name"
    end
  end

  describe "GET /v5/measurement_type/{id}" do
    let!(:measurement) { FactoryGirl.create(:measurement, perm_link: "lmi_total_my_string") }
    let(:json) { JSON.parse(response.body) }

    it "finds measurement based on total_id" do
      get "/v5/measurement_type/#{measurement.total_id}",
        params: {ministry_id: ministry.gr_id},
        headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"}

      expect(response).to be_successful
      expect(json["id"]).to be measurement.id
      expect(json["english"]).to_not be_nil
      expect(json["english"]).to eq measurement.english
    end

    it "finds measurement based on perm_link" do
      get "/v5/measurement_type/my_string", params: {ministry_id: ministry.gr_id},
                                            headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"}

      expect(json["id"]).to be measurement.id
    end
  end

  describe "POST /v5/measurement_types" do
    let(:json) { JSON.parse(response.body) }

    let(:attributes) do
      {
        perm_link_stub: "nbr_nonstaff_reporting",
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

    before do
      WebMock.stub_request(:post, "#{ENV["GLOBAL_REGISTRY_URL"]}/measurement_types")
        .to_return(status: 200, body: {measurement_type: {id: SecureRandom.uuid}}.to_json, headers: {})
    end

    it "creates a measurement type" do
      post "/v5/measurement_types", params: attributes,
                                    headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"}

      expect(response.code.to_i).to be 201
      expect(json["id"]).to_not be_nil

      expect(Measurement.last.english).to eq "Number of Non-Staff Reporting"

      expect(MeasurementTranslation.last.name).to eq "Présenter le Saint-Esprit"
    end
  end

  describe "PUT /v5/measurement_type/:id" do
    let(:json) { JSON.parse(response.body) }
    let(:measurement) { FactoryGirl.create(:measurement) }
    let(:parent_meas) { FactoryGirl.create(:measurement) }

    let(:attributes) { {english: "different name", parent_id: parent_meas.total_id, sort_order: 10} }

    it "updates measurement type without locale params" do
      put "/v5/measurement_types/#{measurement.total_id}",
        params: attributes,
        headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"}

      old_m_attributes = measurement.attributes
      measurement.reload
      new_m_attributes = measurement.attributes
      what_changed = Hash[*(old_m_attributes.to_a - new_m_attributes.to_a).flatten]
        .except("updated_at", "created_at")

      expect(response.code.to_i).to be 200
      # expect that the object was rendered on the way back
      expect(json["id"]).to be measurement.id
      # we don't want other things changing without us knowing
      expect(what_changed.count).to be 3
      expect(measurement.english).to eq "different name"
      expect(measurement.parent.id).to eq parent_meas.id
      expect(measurement.sort_order).to be 10
    end

    it "doesn't update perm_link" do
      measurement.update(perm_link: "lmi_total_custom_reporting")

      expect {
        put "/v5/measurement_types/#{measurement.total_id}",
          params: attributes,
          headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"}
      }.to_not change { measurement.reload.perm_link }
    end

    it "updates measurement translation" do
      translation = FactoryGirl.create(:measurement_translation, measurement: measurement,
                                                                 language: "fr", ministry: ministry)

      expect {
        put "/v5/measurement_types/#{measurement.total_id}",
          params: {locale: "fr", ministry_id: ministry.gr_id, localized_name: "Totally different"},
          headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"}
      }.to change(MeasurementTranslation, :count).by(0)
      translation.reload
      expect(translation.name).to eq "Totally different"
    end

    it "creates measurement translation" do
      expect {
        put "/v5/measurement_types/#{measurement.total_id}",
          params: {locale: "fr", ministry_id: ministry.gr_id, localized_name: "Totally different"},
          headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"}
      }.to change(MeasurementTranslation, :count).by(1)

      translation = measurement.measurement_translations.last
      expect(translation.name).to eq "Totally different"
      expect(translation.language).to eq "fr"
    end
  end
end
