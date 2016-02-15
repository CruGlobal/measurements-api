require 'rails_helper'

RSpec.describe 'V5::Tokens', type: :request do
  describe 'GET /v5_tokens' do
    before :each do
      validate_ticket_request(user)
    end

    context 'with unknown user' do
      let(:user) do
        FactoryGirl.build(:person)
      end

      before do
        gr_person_request_by_guid(user)
      end

      it 'responds with session_ticket' do
        get '/v5/token', st: 'asdf'
        json = JSON.parse(response.body)

        expect(response).to be_success
        expect(json['session_ticket']).to_not be_nil
      end
    end

    context 'with existing user' do
      let(:user) do
        FactoryGirl.create(:person)
      end

      it 'responds with session_ticket' do
        get '/v5/token', st: 'asdf'
        json = JSON.parse(response.body)

        expect(response).to be_success
        expect(json['session_ticket']).to_not be_nil
      end
    end
  end
end
