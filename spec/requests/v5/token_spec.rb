require 'rails_helper'

RSpec.describe 'V5::Tokens', type: :request do
  describe 'GET /v5_tokens' do
    let(:user) do
      Person.create(first_name: 'Test', last_name: 'User',
                    cas_guid: '3719A628-9EFC-4D62-B019-0C7B8D066F55')
    end
    let(:cas_validate_response) do
      email = 'test.user@example.com'
      pgt_iou = 'PGTIOU-1234-abcdef0123456789'
      %(
        <cas:serviceResponse xmlns:cas="http://www.yale.edu/tp/cas">
          <cas:authenticationSuccess>
            <cas:user>#{email}</cas:user>
            <cas:attributes>
              <firstName>#{user.first_name}</firstName>
              <lastName>#{user.last_name}</lastName>
              <theKeyGuid>#{user.cas_guid}</theKeyGuid>
              <relayGuid>#{user.cas_guid}</relayGuid>
              <email>#{email}</email>
              <ssoGuid>#{user.cas_guid}</ssoGuid>
            </cas:attributes>
            <cas:proxyGrantingTicket>#{pgt_iou}</cas:proxyGrantingTicket>
          </cas:authenticationSuccess>
        </cas:serviceResponse>
      )
    end

    it 'respons with session_ticket' do
      WebMock.stub_request(:get, 'https://thekey.me/cas/proxyValidate?service=http://www.example.com/v5/token&ticket=asdf')
             .to_return(status: 200, body: cas_validate_response)
      WebMock.stub_request(:get, 'https://api.global-registry.org/entities?entity_type=person&' \
                                   'fields=first_name,last_name,key_username,authentication.key_guid&' \
                                   "filters%5Bauthentication%5D%5Bkey_guid%5D=#{user.cas_guid}")
             .to_return(status: 200, body: { entities: [] }.to_json, headers: {})

      get '/v5/token', st: 'asdf'
      json = JSON.parse(response.body)

      expect(response).to be_success
      expect(json['session_ticket']).to_not be_nil
    end
  end
end
