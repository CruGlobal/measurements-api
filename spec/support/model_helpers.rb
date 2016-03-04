module ModelHelpers
  def flatten_assignment(assignment)
    assignment = assignment.with_indifferent_access
    assignments = [assignment]
    assignment[:sub_ministries].each do |a|
      assignments << flatten_assignment(a)
    end if assignment.key?(:sub_ministries)
    assignments.flatten
  end
end
