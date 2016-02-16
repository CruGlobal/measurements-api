require 'rails_helper'

RSpec.describe 'V5::Churches', type: :request do
  describe 'GET /v5/churches' do
    let!(:church) { FactoryGirl.create(:church_with_ministry) }
    let(:json) { JSON.parse(response.body) }

    it 'responds with churches' do
      get '/v5/churches', { show_all: true, ministy_id: SecureRandom.uuid },
          'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"

      expect(response).to be_success
      expect(json.length).to be 1
    end
  end

  describe 'POST /v5/churches' do
    let(:ministry) { FactoryGirl.create(:ministry) }
    let!(:church) { FactoryGirl.build(:church, target_area: ministry) }
    let(:json) { JSON.parse(response.body) }

    it 'creates a church' do
      expect do
        attributes = church.attributes.with_indifferent_access
        attributes[:ministry_id] = attributes.delete(:target_area_id)
        post '/v5/churches', attributes,
             'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"

        expect(response).to be_success
      end.to change { Church.count }.by 1
    end
  end
end
