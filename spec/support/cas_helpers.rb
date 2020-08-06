# frozen_string_literal: true

module CASHelpers
  def validate_ticket_request(person, ticket = nil)
    person ||= FactoryBot.build(:person)
    ticket ||= "asdf"
    WebMock
      .stub_request(:get, "#{ENV["CAS_BASE_URL"]}/proxyValidate")
      .with(query: {service: "http://www.example.com/v5/token", ticket: ticket})
      .to_return(status: 200, body: validate_ticket_response(person))
  end

  def validate_ticket_response(person)
    %(
        <cas:serviceResponse xmlns:cas="http://www.yale.edu/tp/cas">
          <cas:authenticationSuccess>
            <cas:user>#{person.cas_username}</cas:user>
            <cas:attributes>
              <firstName>#{person.first_name}</firstName>
              <lastName>#{person.last_name}</lastName>
              <theKeyGuid>#{person.cas_guid}</theKeyGuid>
              <relayGuid>#{person.cas_guid}</relayGuid>
              <email>#{person.cas_username}</email>
              <ssoGuid>#{person.cas_guid}</ssoGuid>
            </cas:attributes>
          </cas:authenticationSuccess>
        </cas:serviceResponse>
      )
  end

  def invalid_ticket_response
    %(
      <cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>
          <cas:authenticationFailure code="INVALID_TICKET">
             ticket PT-1856376-1HMgO86Z2ZKeByc5XdYD not recognized
          </cas:authenticationFailure>
      </cas:serviceResponse>
    )
  end
end
