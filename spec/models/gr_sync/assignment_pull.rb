# frozen_string_literal: true
require 'rails_helper'

describe GrSync::AssignmentPull, '#sync' do
  context '#sync' do
    it 'updates an existing assignment' do
      ministry = create(:ministry)
      person = create(:person)
      assignment = create(:assignment, person: person, ministry: ministry,
                                       role: 'leader')
      person_relationship = {
        'person' => person.gr_id, 'relationship_entity_id' => assignment.gr_id,
        'team_role' => 'admin'
      }

      GrSync::AssignmentPull.new(ministry, person_relationship).sync

      expect(assignment.reload.role).to eq 'admin'
    end

    it 'creates a new assignment if one is missing' do
      ministry = create(:ministry)
      person_gr_id = SecureRandom.uuid
      assignment_gr_id = SecureRandom.uuid
      person = create(:person)
      allow(Person).to receive(:person_for_gr_id) { person }
      person_relationship = {
        'person' => person_gr_id, 'relationship_entity_id' => assignment_gr_id,
        'team_role' => 'leader'
      }

      expect do
        GrSync::AssignmentPull.new(ministry, person_relationship).sync
      end.to change(Assignment, :count).by(1)

      expect(Person).to have_received(:person_for_gr_id).with(person_gr_id)
      assignment = Assignment.last
      expect(assignment.person).to eq person
      expect(assignment.ministry).to eq ministry
      expect(assignment.role).to eq 'leader'
      expect(assignment.gr_id).to eq assignment_gr_id
    end
  end
end
