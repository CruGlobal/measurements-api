# frozen_string_literal: true
module V5
  class ApiErrorSerializer < ActiveModel::Serializer
    attributes :reason

    def reason
      object.message == 'Bad token' ? 'INVALID_SESSION' : object.message
    end
  end
end
