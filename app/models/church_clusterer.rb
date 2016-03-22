# frozen_string_literal: true
class ChurchClusterer
  MAP_WIDTH = 848.0
  MAP_HEIGHT = 600.0
  CLUSTER_LIMIT = 50.0

  def initialize(filters)
    @filters = filters
  end

  def cluster(churches)
    result = []
    @churches = churches.to_a
    @remaining = @churches.clone
    while @remaining.any?
      church_group = nearby_churches(@remaining[0])
      override_parent_ids(church_group)
      result << (church_group.one? ? church_group[0] : church_group)
      remove_from_remaining(church_group)
    end
    result
  end

  private

  def nearby_churches(church)
    [church] + @remaining.select { |c| c != church && are_close_enough(c, church) }
  end

  def are_close_enough(c1, c2)
    lat_distance = (c1.latitude - c2.latitude).abs
    return false if lat_distance > geo_y_limit
    long_distance = (c1.longitude - c2.longitude).abs
    long_distance < geo_x_limit
  end

  def override_parent_ids(church_group)
    # skip the first item because it's children already have it as parent_id
    church_group.drop(1).each do |c|
      @churches.each do |orginal_church|
        # find things that have c.id as their parent_id
        next unless orginal_church.parent_id == c.id
        # then set their parent_cluster_id to church_group.first.id
        # we can set these inside of the @churches array because the models are shared by reference
        orginal_church.parent_cluster_id = church_group.first.id
      end
    end
  end

  def remove_from_remaining(church_group)
    church_group.each do |c|
      @remaining.delete c
    end
  end

  def geo_x_limit
    # watch out for max being less than min if it streches over dateline
    (@filters[:long_max] - @filters[:long_min]).abs * CLUSTER_LIMIT / MAP_WIDTH
  end

  def geo_y_limit
    (@filters[:lat_max] - @filters[:lat_min]) * CLUSTER_LIMIT / MAP_HEIGHT
  end
end
