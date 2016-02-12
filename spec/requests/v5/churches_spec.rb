require 'rails_helper'

RSpec.describe 'V5::Churches', type: :request do
  describe 'GET /v5/churches' do
    let!(:church) do
      FactoryGirl.create(:church)
    end

    it 'responds with churches' do
      get '/v5/churches', { show_all: true, ministy_id: SecureRandom.uuid },
          'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"
      json = JSON.parse(response.body)

      expect(response).to be_success
      expect(json.length).to be 1
    end
  end
end
