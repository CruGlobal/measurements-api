class TokenAndUser < ActiveModelSerializers::Model
  alias_method :read_attribute_for_serialization, :send

  attr_accessor :access_token, :person

  def initialize(access_token, person)
    @access_token = access_token
    @person = person
  end

  def status
    'success'
  end

  def session_ticket
    @access_token.attributes[:token]
  end

  def assignments
    []
  end
end
