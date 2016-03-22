# frozen_string_literal: true
module V5
  class TeamMemberSerializer < ActiveModel::Serializer
    attributes :person_id,
               :assignment_id,
               :team_role,
               :first_name,
               :last_name,
               :key_username,
               :key_guid

    def attributes(args)
      # Remove nil values
      super(args).reject { |_k, v| v.nil? }
    end

    def assignment_id
      object.gr_id
    end

    def person_id
      object.person.try(:gr_id)
    end

    def first_name
      object.person.try(:first_name)
    end

    def last_name
      object.person.try(:last_name)
    end

    def key_username
      object.person.try(:cas_username)
    end

    def key_guid
      object.person.try(:cas_guid)
    end
  end
end
