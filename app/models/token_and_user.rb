class TokenAndUser < ActiveModelSerializers::Model
  attr_accessor :access_token, :person

  def initialize(access_token, person)
    @access_token = access_token
    @person = person
  end

  def assignments
    []
  end

  def attributes
    {
      access_token: @access_token,
      person: @person,
      status: 'success',
      session_ticket: @access_token.attributes[:token]
    }
  end
end
