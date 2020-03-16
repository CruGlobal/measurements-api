# frozen_string_literal: true

module V5
  class AssignmentsController < V5::BaseUserController
    include V5::AssignmentsConcern[authorize: true]
  end
end
