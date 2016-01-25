class Ministry < ActiveRecord::Base
  def update_from_gr(ministry)
    params = {
      ministry_id: ministry.id,
      name: ministry.name,
      parent_ministry_id: ministry.parent_id,
      lmi_hide: ministry.lmi_hide.nil? ? [] : ministry.lmi_hide.split(','),
      lmi_show: ministry.lmi_show.nil? ? [] : ministry.lmi_show.split(','),
      slm: ministry.has_slm,
      llm: ministry.has_llm,
      gcm: ministry.has_gcm,
      ds: ministry.has_ds,
      zoom: ministry.location_zoom,
      lat: ministry.location && ministry.location.key?('latitude') ? ministry.location['latitude'].to_f : nil,
      long: ministry.location && ministry.location.key?('longitude') ? ministry.location['longitude'].to_f : nil
    }
    self.attributes = params
  end

  class << self
    def ministries(refresh = false)
      GlobalRegistry::Ministry.all do |gr_ministry|
        ministry = find_by(ministry_id: gr_ministry.id)
        ministry = Ministry.new if ministry.nil?
        ministry.update_from_gr(gr_ministry)
        ministry.save
      end if refresh
      all
    end

    def ministry(id, refresh = false)
      ministry = find_by(ministry_id: id)
      if ministry.nil? || refresh
        gr_ministry = GlobalRegistry::Ministry.find_by_ministry_id(id)
        return nil if gr_ministry.nil?
        ministry = Ministry.new unless ministry
        ministry.update_from_gr(gr_ministry)
        ministry.save
      end
      ministry
    end
  end
end
