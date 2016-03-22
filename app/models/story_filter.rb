# frozen_string_literal: true
class StoryFilter
  DEFAULT_PAGE = 1
  DEFAULT_PER_PAGE = 5

  def initialize(filters, scope)
    filters = filters.permit(:per_page, :page, :mcc, :church_id, :training_id, :self_only)
    # strip extra spaces from filters
    filters.each { |k, v| filters[k] = v.strip if v.is_a?(String) }
    @filters = filters
    @scope = filter(scope)
  end

  def filtered
    @scope
  end

  def page
    page_int = filters[:page].try(:to_i) || DEFAULT_PAGE
    page_int.to_i > 0 ? page_int : DEFAULT_PAGE
  end

  def per_page
    per_page_int = filters[:per_page].try(:to_i) || DEFAULT_PER_PAGE
    per_page_int.to_i > 0 ? per_page_int : DEFAULT_PER_PAGE
  end

  private

  attr_accessor :filters

  def filter(scope)
    scope = filter_mcc(scope)
    scope = filter_church(scope)
    scope = filter_training(scope)
    scope = filter_self_only(scope)
    filter_paging(scope)
  end

  def filter_mcc(scope)
    if filters.key?(:mcc) && Ministry::MCCS.include?(filters[:mcc])
      scope.where(mcc: filters[:mcc])
    else
      scope
    end
  end

  def filter_church(scope)
    filters.key?(:church_id) ? scope.where(church_id: filters[:church_id]) : scope
  end

  def filter_training(scope)
    filters.key?(:training_id) ? scope.where(training_id: filters[:training_id]) : scope
  end

  def filter_self_only(scope)
    self_only = filters.key?(:self_only) ? bool_value(filters[:self_only]) : false
    if self_only && Power.current
      scope.where(created_by_id: Power.current.user.id)
    else
      scope.where(state: Story.states[:published])
    end
  end

  def filter_paging(scope)
    scope.paginate(page: page, per_page: per_page)
  end

  # convert stings like '1' to booleans
  def bool_value(value)
    value = @filters[value] if value.is_a? Symbol
    ActiveRecord::Type::Boolean.new.type_cast_from_user(value)
  end
end
