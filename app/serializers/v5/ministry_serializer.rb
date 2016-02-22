module V5
  class MinistrySerializer < ActiveModel::Serializer
    attributes :ministry_id,
               :name,
               :min_code,
               :ministry_scope,
               :location,
               :location_zoom,
               :lmi_show,
               :lmi_hide,
               :mccs,
               :parent_id,
               :default_mcc,
               :hide_reports_tab,
               :content_locales

    has_many :assignments, key: :team_members, serializer: TeamMemberSerializer
    has_many :children, key: :sub_ministries, serializer: MinistrySubMinistrySerializer

    def ministry_id
      object.gr_id
    end

    def parent_id
      object.parent.try(:gr_id)
    end

    def content_locales
      # Array of locales
      object.user_content_locales.pluck(:locale).try(:uniq)
    end
  end
end
