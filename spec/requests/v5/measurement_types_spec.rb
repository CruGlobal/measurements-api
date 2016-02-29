require 'rails_helper'

RSpec.describe 'V5::MeasurementTypes', type: :request do
  let(:ministry) { FactoryGirl.create(:ministry) }
  let(:user) { FactoryGirl.create(:person) }
  let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: 7) }

  describe 'GET /v5/measurement_types' do
    let(:json) { JSON.parse(response.body) }
    let!(:measurement) { FactoryGirl.create(:measurement, english: 'English Name') }

    it 'responds with measurement types' do
      get '/v5/measurement_types', { ministry_id: ministry.gr_id, locale: 'en' },
          'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

      expect(response).to be_success
      expect(json.first['id']).to be measurement.id
      expect(json.first['localized_name']).to eq 'English Name'
    end
  end

  describe 'GET /v5/measurement_type/{id}' do
    let!(:measurement) { FactoryGirl.create(:measurement, perm_link: 'lmi_total_my_string') }
    let(:json) { JSON.parse(response.body) }

    it 'finds measurement based on total_id' do
      get "/v5/measurement_type/#{measurement.total_id}", { ministry_id: ministry.gr_id },
          'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

      expect(response).to be_success
      expect(json['id']).to be measurement.id
    end

    it 'finds measurement based on perm_link' do
      get '/v5/measurement_type/my_string', { ministry_id: ministry.gr_id },
          'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

      expect(json['id']).to be measurement.id
    end
  end

  describe 'POST /v5/measurement_types' do
    let(:json) { JSON.parse(response.body) }

    let(:attributes) do
      {
        perm_link_stub: 'nbr_nonstaff_reporting',
        english: 'Number of Non-Staff Reporting',
        description: 'Number of Non-Staff Reporting',
        localized_name: 'Présenter le Saint-Esprit',
        localized_description: "Nombre de personnes avec lesquelles le ministère de l'Esprit Saint",
        section: 'other',
        column: 'other',
        sort_order: 99,
        ministry_id: ministry.gr_id,
        locale: 'fr'
      }
    end

    before do
      WebMock.stub_request(:post, "#{ENV['GLOBAL_REGISTRY_URL']}measurement_types")
             .to_return(status: 200, body: { measurement_type: { id: SecureRandom.uuid } }.to_json, headers: {})
    end

    it 'creates a measurement type' do
      post '/v5/measurement_types', attributes,
           'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

      expect(response).to be_success
      expect(json['id']).to_not be_nil

      expect(Measurement.last.english).to eq 'Number of Non-Staff Reporting'

      expect(MeasurementTranslation.last.name).to eq 'Présenter le Saint-Esprit'
    end
  end

  describe 'PUT /v5/measurement_type/:id' do
    # let(:json) { JSON.parse(response.body) }
    # let(:measurement) { FactoryGirl.create(:measurement) }
    #
    # let(:attributes) { { } }
    #
    # it 'updates measurement type' do
    #   put "/v5/measurement_type/#{measurement.total_id}", attributes,
    #       'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"
    #
    #   expect(response).to be_success
    #   measurement.reload
    #   expect(json['id']).to_not be_nil
    # end
  end
end
