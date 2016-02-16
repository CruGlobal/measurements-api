module V5
  class TokenController < V5::BaseUserController
    before_action :authenticate_request, except: [:index]

    def index
      api_error "You must pass in a service ticket ('st' parameter)" and return if params[:st].blank?

      st = validate_service_ticket(params[:st])
      api_error 'denied' and return unless st.is_valid?

      access_token = generate_access_token(st)
      store_service_ticket(st, access_token)

      person = Person.person(access_token.key_guid)
      api_error 'denied' and return unless person

      render json: TokenAndUser.new(access_token: access_token, person: person), serializer: V5::TokenAndUserSerializer
    end

    def destroy
      CruLib::AccessToken.del(@access_token.token)
      render status: :ok, plain: 'OK'
    end

    protected

    # Validate Service Ticket
    def validate_service_ticket(ticket)
      st = CASClient::ServiceTicket.new(ticket, v5_token_index_url)
      RubyCAS::Filter.client.validate_service_ticket(st)
    end

    # Generate Access Token
    def generate_access_token(st)
      map = { guid: 'ssoGuid', email: 'email', key_guid: 'theKeyGuid',
              relay_guid: '', first_name: 'firstName', last_name: 'lastName' }
      attributes = {}
      map.each do |k, v|
        attributes[k] = st.extra_attributes[v] if st.extra_attributes.key?(v)
      end
      CruLib::AccessToken.new(attributes)
    end

    # Stores a Service Ticket to Access Token relationship
    # This is used to invalidate access tokens when CAS session expires
    def store_service_ticket(ticket, token)
      CruLib.redis_client.setex(redis_ticket_key(ticket), 2.hours.to_i, token.token)
    end
  end
end
