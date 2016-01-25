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

  def mccs
    []
  end

  def location
    { latitude: object.lat, longitude: object.long }
  end

  def location_zoom
    object.zoom
  end

  def parent_id
    object.parent_ministry_id
  end
end
