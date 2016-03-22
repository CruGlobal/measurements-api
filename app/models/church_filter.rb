# frozen_string_literal: true
class ChurchFilter
  def initialize(filters)
    # strip extra spaces from filters
    filters.each { |k, v| filters[k] = v.strip if v.is_a?(String) }
    @filters = filters
  end

  def filter(churches)
    filtered_churches = filter_tree_and_show_all(churches)
    filtered_churches = filter_by_development(filtered_churches)
    filtered_churches = filter_by_lat_long(filtered_churches)
    filter_by_period(filtered_churches)
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
    if Power.current && !Power.current.role_approved?
      return churches.where(public) if clean_filter(:show_all)
      return Church.none
    end

    # this code was built off this example:
    # https://robots.thoughtbot.com/using-arel-to-compose-sql-queries
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

  def filter_by_period(churches)
    return churches if @filters[:period].blank?
    begin
      period_date = Date.parse @filters[:period]
    rescue ArgumentError
      period_date = Date.parse("#{@filters[:period]}-01")
    end
    churches.where('start_date <= ?', period_date.end_of_month).where('end_date > ?', period_date)
  end

  private

  # methods that tell us about the user and the ministry they are requesting
  def ministry_list
    root_ministry.descendants.pluck(:id)
  end

  def root_ministry
    Ministry.find_by(gr_id: @filters[:ministry_id])
  end

  def user_approved
    return false unless root_ministry
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
    table[:ministry_id].in(min_tree_ids).and(table[:security].gteq(1))
  end

  def local_security
    secure_level = if Power.current
                     Power.current.visiable_local_churches_security
                   else
                     Church.securities['local_private_church']
                   end
    table[:ministry_id].eq(root_ministry.try(:id)).and(table[:security].gteq(secure_level))
  end

  def table
    Church.arel_table
  end
end
