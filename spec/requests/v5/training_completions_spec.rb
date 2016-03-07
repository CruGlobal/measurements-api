require 'rails_helper'

RSpec.describe 'V5::TrainingCompletions', type: :request do
  let(:ministry) { FactoryGirl.create(:ministry) }
  let(:user) { FactoryGirl.create(:person) }
  let(:json) { JSON.parse(response.body) }
  let!(:training) { FactoryGirl.create(:training, ministry: ministry) }

  describe 'POST /v5/training_completion' do
    let(:attributes) do
      FactoryGirl.attributes_for(:training_completion, training_id: training.id, number_completed: 42)
    end

    context 'as admin' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :admin) }
      it 'creates a completion' do
        expect do
          post '/v5/training_completion', attributes,
               'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

          expect(response).to be_success
        end.to change(TrainingCompletion, :count).by(1)
        expect(json['phase']).to_not be_nil
      end

      it 'updates existing completion if the phase already exists' do
        training.completions.create(attributes.merge(number_completed: 1))

        expect do
          post '/v5/training_completion', attributes,
               'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

          expect(response).to be_success
        end.to_not change(TrainingCompletion, :count)
        expect(training.completions.last.number_completed).to eq attributes[:number_completed]
      end
    end

    context 'as self-assigned' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :self_assigned) }
      it 'fails to create completion' do
        expect do
          post '/v5/training_completion', attributes,
               'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

          expect(response).to_not be_success
        end.to_not change(TrainingCompletion, :count)
      end
    end
  end

  describe 'PUT /v5/training_completion/:id' do
    let(:completion) { FactoryGirl.create(:training_completion, training: training) }
    let(:other_local_training) { FactoryGirl.create(:training, ministry: ministry) }

    let(:attributes) { { number_completed: 50, date: '2014-12-1' } }

    context 'as admin' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :admin) }
      it 'updates completion' do
        put "/v5/training_completion/#{completion.id}", attributes,
            'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

        expect(response).to be_success
        completion.reload
        expect(completion.number_completed).to be 50
        expect(json['training_id']).to be training.id
      end

      context 'moving to other training' do
        it 'fails to update completion' do
          put "/v5/training_completion/#{completion.id}",
              attributes.merge(training_id: other_local_training.id),
              'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

          completion.reload
          expect(completion.training).to eq training
        end
      end
    end

    context 'as self-assigned' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :self_assigned) }

      it 'fails to update completion' do
        put "/v5/training_completion/#{completion.id}", { number_completed: 30 },
            'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

        expect(response).to_not be_success
      end
    end
  end

  describe 'DELETE /v5/training_completion/:id' do
    let!(:completion) { FactoryGirl.create(:training_completion, training: training) }

    context 'as admin' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :admin) }
      it 'deletes completion' do
        expect do
          delete "/v5/training_completion/#{completion.id}", nil,
                 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

          expect(response).to be_success
        end.to change(TrainingCompletion, :count).by(-1)
      end
    end

    context 'as self-assigned' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :self_assigned) }

      it 'fails to delete completion' do
        expect do
          delete "/v5/training_completion/#{completion.id}", nil,
                 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

          expect(response).to_not be_success
        end.to_not change(TrainingCompletion, :count)
      end
    end
  end
end
