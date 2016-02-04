class ChurchFilters
  attr_accessor :churches, :filters, :current_user

  def initialize(filters, current_user)
    # strip extra spaces from filters
    @filters = filters.map { |k, v| @filters[k] = v.strip if v.is_a?(String) }
    @current_user = current_user
  end

  def filter(churches)
    @churches = filtered_churches = churches
    # filtered_churches = filter_tree_and_show_all(filtered_churches)
    filter_by_development(filtered_churches)
  end

  def filter_by_development(churches)
    include_devs = []
    include_devs << 1 unless clean_filter(:hide_target_point)
    include_devs << 2 unless clean_filter(:hide_group)
    include_devs << 3 unless clean_filter(:hide_church)
    include_devs << 5 unless clean_filter(:hide_mult_church)
    churches.where(development: include_devs)
  end

  def filter_tree_and_show_all(churches)
    return churches.where('security >= 2') if no_access
    show_all = clean_filter(:show_all)
    show_tree = clean_filter(:show_tree)
    ministry_list = show_tree ? [filters[:ministry_id]] : Ministry.find(filters[:ministry_id]).tree_ids
    # query for being in your ministries and visible to you
    query = 'target_area_id IN ?'
    # add on all visible churches
    query = "(#{query}) OR security >= 2" if show_all
    churches.where(query, ministry_list)
  end

  private

  def no_access
    !Ministy.find(filters[:ministry_id]).has_permission(current_user)
  end

  def clean_filter(value)
    value = filters[:value] if value.is_a? Symbol
    ActiveRecord::Type::Boolean.new.type_cast_from_user(value)
  end
end
