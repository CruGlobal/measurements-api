# frozen_string_literal: true
module GrSync
  class AssignmentPull
    def initialize(ministry, person_relationship)
      @ministry = ministry
      @relationship = person_relationship
    end

    def sync
      return if @relationship.key?('created_by') && @relationship['created_by'] != ENV.fetch('GLOBAL_REGISTRY_SYSTEM_ID')
      return unless @relationship.key?('team_role')
      create_or_update_assignment
    end

    private

    def create_or_update_assignment
      assignment_gr_id = @relationship['relationship_entity_id']
      person = Person.person_for_gr_id(@relationship['person'])
      assignment = Assignment.find_or_initialize_by(ministry: @ministry, person: person)

      # We will update/create the assignment for this (ministry, person) pair if
      # either there is no assignment for that ministry and person or if the
      # role we currently have for that ministry and person is a lower-level
      # role (by enum number) than the role for this new relationship we are
      # pulling in. That helps us resolve duplicate assignments in global
      # registry by taking the one with the highest authority.
      return unless assignment.new_record? ||
                    Assignment.roles[assignment.role] < relationship_role_number

      assignment.update!(gr_id: assignment_gr_id, role: relationship_role_number)
    end

    def relationship_role_number
      @role ||= Assignment.roles[@relationship['team_role'].to_sym]
    end
  end
end
