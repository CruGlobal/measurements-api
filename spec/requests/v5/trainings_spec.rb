require 'rails_helper'

RSpec.describe 'V5::Churches', type: :request do
  let(:ministry) { FactoryGirl.create(:ministry) }
  let(:user) { FactoryGirl.create(:person) }

  describe 'GET /v5/trainings' do
    let!(:training) { FactoryGirl.create(:training, ministry: ministry) }
    let(:json) { JSON.parse(response.body) }

    it 'responds with trainings' do
      get '/v5/trainings', { ministry_id: ministry.gr_id },
          'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"

      expect(response).to be_success
      expect(json.first['id']).to be training.id
    end
  end

  describe 'POST /v5/trainings' do
    let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: 7) }
    let(:json) { JSON.parse(response.body) }

    let(:attributes) do
      FactoryGirl.attributes_for(:training, ministry: ministry).merge(ministry_id: ministry.gr_id)
    end

    context 'as admin' do
      before do
        post '/v5/trainings', attributes,
             'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"
      end
      it 'creates a training' do
        expect(response).to be_success
        expect(Audit.last.message).to end_with attributes[:name]
        training = Training.last
        expect(training.name).to eq attributes[:name]
        expect(training.created_by_id).to eq user.id
        expect(json['type']).to_not be_nil
      end

      # we can turn this on when we make the training completions
      it 'also creates a training completion'
      # do
      #   expect(training.completions.count).to eq 1
      # end
    end
  end

  describe 'PUT /v5/trainings/:id' do
  end
end
