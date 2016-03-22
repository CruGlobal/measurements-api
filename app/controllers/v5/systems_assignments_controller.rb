# frozen_string_literal: true
module V5
  class SystemsAssignmentsController < V5::AssignmentsController
    include V5::BaseSystemsController

    private

    def assignment_scope
      Assignment.all
    end
  end
end
