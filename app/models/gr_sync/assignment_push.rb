# frozen_string_literal: true
module GrSync
  class AssignmentPush
    RELATIONSHIP = 'ministry:relationship'

    def initialize(assignment)
      @assignment = assignment
    end

    def push_to_gr
      response = root_gr_client.put(
        person.gr_id, gr_relationship_entity,
        params: { full_response: true, fields: RELATIONSHIP }
      )
      assignment.gr_id = relationship_entity_id(response)
    end

    private

    attr_reader :assignment
    delegate :person, to: :assignment
    delegate :ministry, to: :assignment

    def gr_relationship_entity
      {
        entity: {
          person: {
            client_integration_id: person.id,
            RELATIONSHIP => {
              ministry: ministry.gr_id,
              client_integration_id: "_#{person.gr_id}_#{ministry.gr_id}",
              team_role: assignment.role
            }
          }
        }
      }
    end

    def relationship_entity_id(response)
      assignment = Array.wrap(response['entity']['person'][RELATIONSHIP]).find do |relationship|
        relationship['ministry'] == ministry.gr_id
      end
      assignment['relationship_entity_id']
    end

    def root_gr_client
      # Always create the associated global registry entity for assignments with
      # the root global registry key to prevent a system from gaining
      # higher-than-expected access to the measurements api data.
      GlobalRegistry::Entity.new
    end
  end
end
