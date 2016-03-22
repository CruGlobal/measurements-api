# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'V5::Trainings', type: :request do
  let(:ministry) { FactoryGirl.create(:ministry) }
  let(:user) { FactoryGirl.create(:person) }

  describe 'GET /v5/training' do
    let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :admin) }
    let!(:training) { FactoryGirl.create(:training, ministry: ministry) }
    let(:json) { JSON.parse(response.body) }

    it 'responds with trainings' do
      get '/v5/training', { ministry_id: ministry.gr_id },
          'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

      expect(response).to be_success
      expect(json.first['id']).to be training.id
    end
  end

  describe 'POST /v5/training' do
    let(:json) { JSON.parse(response.body) }

    let(:attributes) do
      FactoryGirl.attributes_for(:training, ministry: ministry)
                 .merge(ministry_id: ministry.gr_id, participants: 6)
    end

    context 'as admin' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :admin) }
      before do
        post '/v5/training', attributes,
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

      it 'also creates a training completion' do
        training = Training.last
        expect(training.completions.count).to eq 1
      end
    end

    context 'as self-assigned' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :self_assigned) }
      it 'fails to create training' do
        expect do
          post '/v5/training', attributes,
               'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

          expect(response).to_not be_success
        end.to_not change { Training.count }
      end
    end
  end

  describe 'PUT /v5/training/:id' do
    let(:training) { FactoryGirl.create(:training, ministry: ministry) }
    let(:other_ministry) { FactoryGirl.create(:ministry) }

    let(:json) { JSON.parse(response.body) }

    let(:attributes) { { latitude: 50.5, ministry_id: other_ministry.gr_id } }

    context 'as admin' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :admin) }
      it 'updates training' do
        FactoryGirl.create(:assignment, person: user, ministry: other_ministry, role: :admin)

        put "/v5/training/#{training.id}", attributes,
            'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

        expect(response).to be_success
        training.reload
        expect(training.latitude).to eq attributes[:latitude]
        expect(training.ministry).to eq other_ministry
        expect(json['type']).to_not be_nil
      end

      context 'moving to unapproved ministry' do
        it 'fails to update training' do
          put "/v5/training/#{training.id}", attributes,
              'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

          expect(response).to_not be_success
        end
      end
    end

    context 'as self-assigned' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :self_assigned) }

      it 'fails to update training' do
        put "/v5/training/#{training.id}", { latitude: 60.7 },
            'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

        expect(response).to_not be_success
      end
    end
  end

  describe 'DELETE /v5/training/:id' do
    let(:training) { FactoryGirl.create(:training, ministry: ministry) }
    let!(:completion) { FactoryGirl.create(:training_completion, training: training) }

    context 'as admin' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :admin) }
      it 'deletes training' do
        expect do
          delete "/v5/training/#{training.id}", nil,
                 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

          expect(response).to be_success
        end.to change(Training, :count).by(-1)
          .and(change { TrainingCompletion.count }.to(0))
      end
    end

    context 'as self-assigned' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :self_assigned) }

      it 'fails to delete training' do
        delete "/v5/training/#{training.id}", nil,
               'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

        expect(response).to_not be_success
      end
    end
  end
end
