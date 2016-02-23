require 'rails_helper'

RSpec.describe 'V5::Churches', type: :request do
  let(:ministry) { FactoryGirl.create(:ministry) }
  let(:user) { FactoryGirl.create(:person) }
  let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: 7) }
  let(:json) { JSON.parse(response.body) }
  let!(:training) { FactoryGirl.create(:training, ministry: ministry) }

  describe 'POST /v5/training_completion' do
    let(:attributes) do
      FactoryGirl.attributes_for(:training_completion, training_id: training.id, number_completed: 42)
    end

    context 'as admin' do
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
      before do
        assignment.update(role: 'self_assigned')
      end
      it 'fails to create completion' do
        expect do
          post '/v5/training_completion', attributes,
               'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

          expect(response).to_not be_success
        end.to_not change(TrainingCompletion, :count)
      end
    end
  end
end
