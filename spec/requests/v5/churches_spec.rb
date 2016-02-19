require 'rails_helper'

RSpec.describe 'V5::Churches', type: :request do
  let(:ministry) { FactoryGirl.create(:ministry) }
  let(:user) { FactoryGirl.create(:person) }

  describe 'GET /v5/churches' do
    let!(:church) { FactoryGirl.create(:church_with_ministry) }
    let(:json) { JSON.parse(response.body) }

    it 'responds with churches' do
      get '/v5/churches', { show_all: true, ministy_id: SecureRandom.uuid },
          'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"

      expect(response).to be_success
      expect(json.first['id']).to be church.id
    end
  end

  describe 'POST /v5/churches' do
    let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: 7) }
    let(:json) { JSON.parse(response.body) }

    let(:attributes) do
      FactoryGirl.attributes_for(:church, ministry: ministry, security: 0).merge(ministry_id: ministry.gr_id)
    end

    context 'as admin' do
      it 'creates a church' do
        expect do
          post '/v5/churches', attributes,
               'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

          expect(response).to be_success
        end.to change { Church.count }.by(1).and(change { Audit.count }.by(1))
        expect(Church.last.created_by_id).to eq user.person_id
      end
    end

    context 'as self-assigned' do
      before do
        assignment.update(role: 'self_assigned')
      end
      it 'can create public church' do
        expect do
          post '/v5/churches', attributes.merge(security: 2),
               'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

          expect(response).to be_success
        end.to change { Church.count }
      end
      it 'fails to create private church' do
        expect do
          post '/v5/churches', attributes,
               'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

          expect(response).to_not be_success
        end.to_not change { Church.count }
      end
    end

    context 'as unassociated' do
      it 'fails to create private church' do
        expect do
          post '/v5/churches', attributes,
               'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"

          expect(response).to_not be_success
        end.to_not change { Church.count }
      end
    end
  end

  describe 'PUT /v5/churches/:id' do
    let(:church) { FactoryGirl.create(:church, ministry: ministry) }
    let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: 7) }
    let(:json) { JSON.parse(response.body) }

    let(:attributes) do
      church.size += 1
      church.attributes.with_indifferent_access
    end

    context 'as admin' do
      it 'updates church' do
        put "/v5/churches/#{church.id}", attributes,
            'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

        expect(response).to be_success
        expect(church.reload.size).to eq attributes[:size]
        church_value = church.church_values.last
        expect(church_value).to be_present
        expect(church_value.period).to eq Time.zone.today.strftime('%Y-%m')
      end
    end

    context 'trying to move church to another ministry you do not have access to' do
      it 'fails to update' do
        assignment.update(role: 'self_assigned')
        other_ministry = FactoryGirl.create(:ministry)

        put "/v5/churches/#{church.id}", { ministry_id: other_ministry.id },
            'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"

        expect(response).to_not be_success
      end
    end
  end
end
