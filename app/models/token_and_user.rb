class TokenAndUser < ActiveModelSerializers::Model
  attr_accessor :access_token, :person

  def assignments
    []
  end

  def attributes
    super.merge(status: 'success',
                session_ticket: @access_token.attributes[:token],
                assignments: assignments)
  end
end
