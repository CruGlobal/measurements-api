# frozen_string_literal: true

module ModelHelpers
  def flatten_assignment(assignment)
    assignment = assignment.with_indifferent_access
    assignments = [assignment]
    if assignment.key?(:sub_ministries)
      assignment[:sub_ministries].each do |a|
        assignments << flatten_assignment(a)
      end
    end
    assignments.flatten
  end
end
