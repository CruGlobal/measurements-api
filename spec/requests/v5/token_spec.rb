require 'rails_helper'

RSpec.describe 'V5::Tokens', type: :request do
  describe 'GET /v5_tokens' do
    before :each do
      WebMock
        .stub_request(:get, "#{ENV['CAS_BASE_URL']}/proxyValidate")
        .with(query: { service: 'http://www.example.com/v5/token', ticket: 'asdf' })
        .to_return(status: 200, body: cas_validate_response)
    end

    let(:cas_validate_response) do
      %(
        <cas:serviceResponse xmlns:cas="http://www.yale.edu/tp/cas">
          <cas:authenticationSuccess>
            <cas:user>#{user[:cas_username]}</cas:user>
            <cas:attributes>
              <firstName>#{user[:first_name]}</firstName>
              <lastName>#{user[:last_name]}</lastName>
              <theKeyGuid>#{user[:cas_guid]}</theKeyGuid>
              <relayGuid>#{user[:cas_guid]}</relayGuid>
              <email>#{user[:cas_username]}</email>
              <ssoGuid>#{user[:cas_guid]}</ssoGuid>
            </cas:attributes>
          </cas:authenticationSuccess>
        </cas:serviceResponse>
      )
    end

    context 'with unknown user' do
      let(:user) do
        { first_name: 'Unknown', last_name: 'User',
          cas_username: 'unknown.user@example.com',
          cas_guid: SecureRandom.uuid.upcase }
      end

      let(:entities_response) do
        {
          person: {
            id: SecureRandom.uuid,
            first_name: user[:first_name],
            key_username: user[:cas_username],
            last_name: user[:last_name],
            authentication: {
              id: SecureRandom.uuid,
              key_guid: user[:cas_guid]
            },
            client_integration_id: '16'
          }
        }
      end

      before do
        WebMock
          .stub_request(:get, "#{ENV['GLOBAL_REGISTRY_URL']}entities")
          .with(query: { entity_type: 'person',
                         fields: 'first_name,last_name,key_username,authentication.key_guid',
                         'filters[authentication][key_guid]': user[:cas_guid] })
          .to_return(status: 200, body: { entities: [entities_response] }.to_json, headers: {})
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
        Person.create(first_name: 'Test', last_name: 'User',
                      cas_username: 'test.user@example.com',
                      cas_guid: SecureRandom.uuid.upcase)
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
