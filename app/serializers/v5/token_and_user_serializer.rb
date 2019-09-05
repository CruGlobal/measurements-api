# frozen_string_literal: true

module V5
  class TokenAndUserSerializer < ActiveModel::Serializer
    attributes :status, :session_ticket, :assignments

    has_one :user
    has_one :user_preferences, serializer: UserPreferencesSerializer

    def user
      {
        first_name: object.access_token.first_name,
        last_name: object.access_token.last_name,
        cas_username: object.access_token.email,
        person_id: object.person.gr_id,
        key_guid: object.person.cas_guid,
      }
    end

    def user_preferences
      object.person
    end

    def assignments
      # We need to serialize ourselves, AMS doesn't serialize nested assignments (by design), we need deep nesting
      object.person.try(:assignments).map { |assignment|
        serializer = V5::AssignmentSerializer.new(assignment)
        ::ActiveModelSerializers::Adapter.create(serializer).as_json
      }.compact
    end
  end
end
