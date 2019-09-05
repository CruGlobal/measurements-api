# frozen_string_literal: true

module V5
  class MinistrySerializer < BaseMinistrySerializer
    has_many :team_members, serializer: TeamMemberSerializer
    has_many :children, key: :sub_ministries, serializer: MinistrySubMinistrySerializer

    attributes :id

    def id
      object.gr_id
    end
  end
end
