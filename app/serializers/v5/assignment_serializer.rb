# frozen_string_literal: true
module V5
  class AssignmentSerializer < BaseMinistrySerializer
    attributes :id, :team_role, :sub_ministries

    delegate :ministry, to: :object
    delegate(*MINISTRY_ATTRIBUTES, to: :ministry)

    def attributes(args = nil)
      # Remove empty :sub_ministries attribute
      super.reject { |k, v| k == :sub_ministries && v.empty? }
    end

    def id
      object.gr_id
    end

    def ministry_id
      ministry.gr_id
    end

    def parent_id
      ministry.parent.try(:gr_id)
    end

    def content_locales
      # Array of locales
      ministry.user_content_locales.pluck(:locale).try(:uniq)
    end

    def sub_ministries
      object.ministry.children.collect do |ministry|
        serializer = V5::AssignmentSerializer.new(object.as_inherited_assignment(ministry.id))
        ::ActiveModelSerializers::Adapter.create(serializer).as_json
      end.compact if object.leader_role?
    end
  end
end
