class MinistrySerializer < ActiveModel::Serializer
  attributes :ministry_id,
             :name,
             :min_code,
             :mccs,
             :default_mcc,
             :location,
             :location_zoom,
             :parent_id
  # :hide_reports_tab,
  # :team_members

  def ministry_id
    object.gr_id
  end

  def parent_id
    object.parent.try(:id)
  end
end
