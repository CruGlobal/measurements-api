# frozen_string_literal: true
module V5
  class SystemsAssignmentsController < V5::AssignmentsController
    include V5::BaseSystemsController

    # Systems endpoint allows updating existing assignments on the create endpoint
    def build_assignment
      @assignment ||= ::Assignment::UserCreatedAssignment.new
      @assignment.attributes = assignment_params
      @assignment.save
    rescue ActiveRecord::RecordNotUnique
      found_assignment = ::Assignment.find_by(person_id: @assignment.person_id, ministry_id: @assignment.ministry_id)
      return nil unless found_assignment.present?
      @assignment = ::Assignment::UserUpdatedAssignment.new(found_assignment)
      @assignment.update(role: assignment_params[:team_role])
    end

    private

    def assignment_scope
      Assignment.all
    end
  end
end
