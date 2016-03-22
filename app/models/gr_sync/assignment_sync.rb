# frozen_string_literal: true
module GrSync
  class AssignmentSync
    def initialize(ministry, person_relationship)
      @ministry = ministry
      @relationship = person_relationship
    end

    def sync
      assignment_gr_id = @relationship['relationship_entity_id']
      assignment = Assignment.find_or_initialize_by(gr_id: assignment_gr_id)
      assignment.update!(
        ministry: @ministry, role: @relationship['team_role'],
        person: Person.person_for_gr_id(@relationship['person']))
    end
  end
end
