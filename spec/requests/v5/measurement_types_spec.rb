require 'rails_helper'

RSpec.describe 'V5::MeasurementTypes', type: :request do
  let(:ministry) { FactoryGirl.create(:ministry) }
  let(:user) { FactoryGirl.create(:person) }
  let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: 7) }

  describe 'GET /v5/measurement_types' do
    let!(:measurement) { FactoryGirl.create(:measurement) }
    let(:json) { JSON.parse(response.body) }

    it 'responds with measurement types' do
      get '/v5/measurement_types', { ministry_id: ministry.gr_id, locale: 'en' },
          'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

      expect(response).to be_success
      expect(json.first['id']).to be measurement.id
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
end
