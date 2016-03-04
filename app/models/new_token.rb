class NewToken
  include ActiveModel::Model
  include ActiveRecord::AttributeAssignment

  attr_accessor :st, :redirect_url

  validates :st, presence: { message: "You must pass in a service ticket ('st' parameter)" }
  validate :validate_service_ticket, :person?

  def save
    TokenAndUser.new(access_token: access_token, person: person)
  end

  private

  # Validate Service Ticket
  def validate_service_ticket
    return if errors.any? || checked_ticket.is_valid?
    errors.add(:st, 'denied')
  end

  def checked_ticket
    return @checked_ticket if @checked_ticket
    st = CASClient::ServiceTicket.new(self.st, redirect_url)
    @checked_ticket = RubyCAS::Filter.client.validate_service_ticket(st)
  end

  def access_token
    @access_token ||= generate_access_token(checked_ticket)
  end

  def person?
    return if errors.any?
    store_service_ticket(checked_ticket, access_token)
    return if person.present?
    errors.add(:st, 'denied')
  end

  def person
    @person ||= Person.person(access_token.key_guid)
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

  def redis_ticket_key(ticket)
    ['measurements_api:service_ticket', ticket].join(':')
  end
end
