class TrainingFilter
  def initialize(filters)
    # strip extra spaces from filters
    filters.each { |k, v| filters[k] = v.strip if v.is_a?(String) }
    @filters = filters
  end

  def filter(trainings)
    filtered_trainings = filter_by_tree(trainings)
    filter_by_time(filtered_trainings)
  end

  def filter_by_tree(trainings)
    trainings.where(ministry_id: ministry_list)
  end

  def filter_by_time(trainings)
    return trainings if clean_filter(:show_all)
    # where date is within the last year or a completion within the last year
    trainings.includes(:completions).references(:training_completions)
             .where('trainings.date > ? or training_completions.date > ?', 1.year.ago, 1.year.ago)
    # but we can't return that yet since training completions aren't there
    trainings.where('date > ?', 1.year.ago)
  end

  private

  # methods that tell us about the user and the ministry they are requesting
  def ministry_list
    if clean_filter(:show_tree)
      root_ministry.descendants.pluck(:id) + [root_ministry.id]
    else
      root_ministry.id
    end
  end

  def root_ministry
    Ministry.find_by(gr_id: @filters[:ministry_id])
  end

  # convert stings like '1' to booleans
  def clean_filter(value)
    value = @filters[value] if value.is_a? Symbol
    ActiveRecord::Type::Boolean.new.type_cast_from_user(value)
  end
end
