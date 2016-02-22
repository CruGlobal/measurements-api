module V5
  class AssignmentSerializer < ActiveModel::Serializer
    attributes :id, :team_role

    def attributes(args)
      data = super
      ministry_serializer = MinistrySerializer.new(object.ministry, instance_options)
      data.merge(ministry_serializer.attributes)
    end

    def id
      object.gr_id
    end
  end
end
