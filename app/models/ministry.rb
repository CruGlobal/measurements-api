class Ministry < ActiveRecord::Base

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
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
      min_code: ministry.min_code
      # lat: ministry.location && ministry.location.key?('latitude') ? ministry.location['latitude'].to_f : nil,
      # long: ministry.location && ministry.location.key?('longitude') ? ministry.location['longitude'].to_f : nil
    }
    self.attributes = params
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity


  # Find ministry by id
  def self.ministry(id, refresh = false)
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
