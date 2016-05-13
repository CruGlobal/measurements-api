# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'V5::SystemsMinistries', type: :request do
  before :all do
    @ministries = FactoryGirl.create(:ministry_hierarchy)
  end
  after :all do
    Ministry.delete_all
    @ministries = nil
  end
  let!(:ministries) { @ministries }
  let(:json) { JSON.parse(response.body) }
  let(:gr_access_toke) { authenticate_api }

  describe 'GET /v5/sys_ministries' do
    it 'responds with all ministries' do
      get '/v5/sys_ministries', nil, 'HTTP_AUTHORIZATION': "Bearer #{gr_access_toke}"
      expect(response).to be_success
      expect(json.length).to be ministries.length
    end

    # context 'with refresh=true' do
    #   it 'responds with HTTP 202 Accepted' do
    #     clear_uniqueness_locks
    #     expect do
    #       get '/v5/sys_ministries', { refresh: true }, 'HTTP_AUTHORIZATION': "Bearer #{gr_access_toke}"
    #       expect(response).to be_success
    #       expect(response).to have_http_status(202)
    #     end.to change(GrSync::WithGrWorker.jobs, :size).by(1)
    #   end
    # end
  end

  describe 'GET /v5/sys_ministries/:id' do
    context 'valid ministry id' do
      it 'responds with the ministry details' do
        get "/v5/sys_ministries/#{ministries[:a3].gr_id}", nil, 'HTTP_AUTHORIZATION': "Bearer #{gr_access_toke}"

        expect(response).to be_success
        expect(response).to have_http_status(200)
        expect(response.body).to include_json(ministry_id: ministries[:a3].gr_id, min_code: ministries[:a3].min_code)
      end
    end

    context 'unknown ministry id' do
      it 'responds with the ministry details' do
        get "/v5/sys_ministries/#{SecureRandom.uuid}", nil, 'HTTP_AUTHORIZATION': "Bearer #{gr_access_toke}"

        expect(response).to_not be_success
        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'POST /v5/sys_ministries' do
    context 'missing required params' do
      it 'responds with HTTP 400' do
        post '/v5/sys_ministries',
             { name: nil, lmi_show: true, mccs: nil, ministry_scope: 'Blah', hello: 123 },
             'HTTP_AUTHORIZATION': "Bearer #{gr_access_toke}"

        expect(response).to_not be_success
        expect(response).to have_http_status 400
      end
    end

    context 'with required params' do
      let(:ministry) { FactoryGirl.build(:ministry) }
      let!(:request_stub) { gr_create_ministry_request(ministry) }

      it 'responds successfully with new ministry' do
        post '/v5/sys_ministries',
             { name: 'Test Ministry', ministry_scope: 'National', parent_id: ministries[:a3].gr_id },
             'HTTP_AUTHORIZATION': "Bearer #{gr_access_toke}"

        expect(response).to be_success
        expect(response).to have_http_status 201
        expect(request_stub).to have_been_requested
        expect(json).to include('ministry_id', 'parent_id', 'min_code')
        expect(json['ministry_id']).to be_uuid.and(eq ministry.gr_id)
      end
    end
  end

  describe 'PUT /v5/sys_ministries/:id' do
    let(:ministry) { FactoryGirl.create(:ministry) }
    context 'valid ministry id' do
      it 'responds with the updated ministry details' do
        allow(GrSync::EntityUpdatePush).to receive(:queue_with_root_gr)

        put "/v5/sys_ministries/#{ministry.gr_id}",
            { name: 'New Name', mccs: ['gcm'], ministry_scope: 'Area' },
            'HTTP_AUTHORIZATION': "Bearer #{gr_access_toke}"

        expect(GrSync::EntityUpdatePush).to have_received(:queue_with_root_gr)
          .with(ministry)
        expect(response).to be_success
        expect(response).to have_http_status(200)
        expect(json).to include_json(ministry_id: ministry.gr_id, name: 'New Name', ministry_scope: 'Area')
      end
    end

    context 'unknown ministry id' do
      it 'responds with the ministry details' do
        put "/v5/sys_ministries/#{SecureRandom.uuid}", nil, 'HTTP_AUTHORIZATION': "Bearer #{gr_access_toke}"

        expect(response).to_not be_success
        expect(response).to have_http_status(404)
      end
    end
  end
end
