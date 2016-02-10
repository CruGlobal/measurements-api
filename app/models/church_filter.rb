class ChurchFilter
  def initialize(filters, current_user)
    # strip extra spaces from filters
    filters.each { |k, v| filters[k] = v.strip if v.is_a?(String) }
    @filters = filters
    @current_user = current_user
  end

  def filter(churches)
    filtered_churches = filter_tree_and_show_all(churches)
    filtered_churches = filter_by_development(filtered_churches)
    filter_by_lat_long(filtered_churches)
  end

  def filter_by_development(churches)
    include_devs = []
    include_devs << Church.developments['target'] unless clean_filter(:hide_target_point)
    include_devs << Church.developments['group_stage'] unless clean_filter(:hide_group)
    include_devs << Church.developments['church'] unless clean_filter(:hide_church)
    include_devs << Church.developments['multiplying_church'] unless clean_filter(:hide_mult_church)
    churches.where(development: include_devs)
  end

  def filter_tree_and_show_all(churches)
    unless user_approved
      churches = churches.where(public) if clean_filter(:show_al)
      return churches
    end

    # this code was built off this example: https://robots.thoughtbot.com/using-arel-to-compose-sql-queries
    query = local_security
    query = query.or(in_tree(ministry_list)) if clean_filter(:show_tree)
    query = query.or(public) if clean_filter(:show_all)
    churches.where(query)
  end

  def filter_by_lat_long(churches)
    return churches if @filters[:lat_max].blank?
    churches = churches.where(latitude: @filters[:lat_min]..@filters[:lat_max])

    if @filters[:long_max] > @filters[:long_min]
      churches.where(longitude: @filters[:long_min]..@filters[:long_max])
    else
      churches.where.not(longitude: @filters[:long_max]..@filters[:long_min])
    end
  end

  private

  # methods that tell us about the user and the ministry they are requesting
  def ministry_list
    root_ministry.descendants_ids
  end

  def root_ministry
    Ministry.find_by(ministry_id: @filters[:ministry_id])
  end

  def root_ministry_roll
    # stub method for what a user's roll is on the current ministry
    'admin'
  end

  def user_approved
    # root_ministry.assignment_of(current_user).approved?
    true
  end

  # convert stings like '1' to booleans
  def clean_filter(value)
    value = @filters[value] if value.is_a? Symbol
    ActiveRecord::Type::Boolean.new.type_cast_from_user(value)
  end

  # arel methods
  def public
    table[:security].gteq(Church.securities['public_church'])
  end

  def in_tree(min_tree_ids)
    table[:target_area_id].in(min_tree_ids).and(table[:security].gteq(1))
  end

  def local_security
    secure_level = if root_ministry_roll.start_with?('inherited_')
                     Church.securities['private_church']
                   else
                     Church.securities['local_private_church']
                   end
    table[:target_area_id].eq(@filters[:ministry_id]).and(table[:security].gteq(secure_level))
  end

  def table
    Church.arel_table
  end
end
