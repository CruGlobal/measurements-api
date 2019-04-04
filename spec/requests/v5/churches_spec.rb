# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'V5::Churches', type: :request do
  let(:ministry) { FactoryGirl.create(:ministry) }
  let(:user) { FactoryGirl.create(:person) }

  describe 'GET /v5/churches' do
    let!(:church) { FactoryGirl.create(:church_with_ministry) }
    let(:json) { JSON.parse(response.body) }

    it 'responds with churches' do
      get '/v5/churches', params: { show_all: true, ministry_id: ministry.gr_id },
                          headers: { 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}" }

      expect(response).to be_successful
      expect(json.first['id']).to be church.id
    end

    it 'gives development stage when looking at past period' do
      church.update(start_date: 2.months.ago.beginning_of_day)

      get '/v5/churches',
          params: { show_all: true, ministry_id: ministry.gr_id, period: 2.months.ago.strftime('%Y-%m') },
          headers: { 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}" }

      expect(response).to be_successful
      expect(json.first['development']).to be 1
    end

    context 'as inherited admin' do
      let(:child_ministry) { FactoryGirl.create(:ministry, parent: ministry) }
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :admin) }

      it 'responds with churches' do
        church.update(ministry: child_ministry)

        get '/v5/churches', params: { ministry_id: child_ministry.gr_id },
                            headers: { 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}" }

        expect(response).to be_successful
        expect(json.first['id']).to be church.id
      end
    end
  end

  describe 'POST /v5/churches' do
    let(:json) { JSON.parse(response.body) }

    let(:attributes) do
      FactoryGirl.attributes_for(:church, ministry: ministry, security: 0).merge(ministry_id: ministry.gr_id)
    end

    context 'as admin' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :admin) }
      it 'creates a church' do
        expect do
          post '/v5/churches', params: attributes,
                               headers: { 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}" }

          expect(response).to be_successful
        end.to change { Church.count }.by(1).and(change { Audit.count }.by(1))
        expect(Church.last.created_by_id).to eq user.id
      end
    end

    context 'as inherited admin' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :admin) }
      let(:child_ministry) { FactoryGirl.create(:ministry, parent: ministry) }
      it 'creates a church' do
        expect do
          post '/v5/churches', params: attributes.merge(ministry_id: child_ministry.gr_id),
                               headers: { 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}" }

          expect(response).to be_successful
        end.to change { Church.count }.by(1).and(change { Audit.count }.by(1))
      end
    end

    context 'as self-assigned' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :self_assigned) }
      it 'can create public church' do
        expect do
          post '/v5/churches', params: attributes.merge(security: 2),
                               headers: { 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}" }

          expect(response).to be_successful
        end.to change { Church.count }
      end
      it 'fails to create private church' do
        expect do
          post '/v5/churches', params: attributes,
                               headers: { 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}" }

          expect(response).to_not be_successful
        end.to_not change { Church.count }
      end
    end

    context 'as self-assigned' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :blocked) }
      it 'fails to create church' do
        expect do
          post '/v5/churches', params: attributes.merge(security: 2),
                               headers: { 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}" }

          expect(response).to_not be_successful
        end.to_not change { Church.count }
      end
    end

    context 'as unassociated' do
      it 'fails to create church' do
        expect do
          post '/v5/churches', params: attributes.merge(security: 2),
                               headers: { 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}" }

          expect(response).to_not be_successful
        end.to_not change { Church.count }
      end
    end
  end

  describe 'PUT /v5/churches/:id' do
    let(:church) { FactoryGirl.create(:church, ministry: ministry) }
    let(:json) { JSON.parse(response.body) }

    let(:attributes) do
      church.size += 1
      church.attributes.with_indifferent_access.merge(ministry_id: ministry.gr_id)
    end

    context 'as admin' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :admin) }
      it 'updates church' do
        put "/v5/churches/#{church.id}", params: attributes,
                                         headers: { 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}" }

        expect(response).to be_successful
        expect(church.reload.size).to eq attributes[:size]
        church_value = church.church_values.last
        expect(church_value).to be_present
        expect(church_value.period).to eq Time.zone.today.strftime('%Y-%m')
      end

      it 'removes parent' do
        child_church = FactoryGirl.create(:church, parent: church, ministry: ministry)

        put "/v5/churches/#{child_church.id}", params: { parent_id: -1 },
                                               headers: { 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}" }

        expect(child_church.reload.parent).to be_nil
      end

      it 'moves 0 security to 1' do
        expect do
          put "/v5/churches/#{church.id}", params: attributes.merge(security: 0),
                                           headers: { 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}" }
        end.to change { church.reload.security }.to('private_church')
      end
    end

    context 'as inherited admin' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :admin) }
      let(:child_ministry) { FactoryGirl.create(:ministry, parent: ministry) }

      it 'updates church' do
        church.update(ministry: child_ministry)

        put "/v5/churches/#{church.id}", params: attributes.merge(ministry_id: child_ministry.gr_id),
                                         headers: { 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}" }

        expect(response).to be_successful
        expect(church.reload.size).to eq attributes[:size]
        church_value = church.church_values.last
        expect(church_value).to be_present
        expect(church_value.period).to eq Time.zone.today.strftime('%Y-%m')
      end
    end

    context 'trying to move church to another ministry you do not have access to' do
      let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :admin) }
      it 'fails to update' do
        other_ministry = FactoryGirl.create(:ministry)

        put "/v5/churches/#{church.id}", params: { ministry_id: other_ministry.id },
                                         headers: { 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}" }

        expect(response).to_not be_successful
      end
    end
  end
end
