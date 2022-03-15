# frozen_string_literal: true

class TokenAndUser < ActiveModelSerializers::Model
  attr_accessor :access_token, :person, :status

  def assignments
    []
  end

  def status
    "success"
  end

  def session_ticket
    @access_token.attributes[:token]
  end
end
