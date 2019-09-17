# frozen_string_literal: true

require "rails_helper"

describe GrSync::AssignmentPull, "#sync" do
  context "#sync" do
    it "updates an existing assignment" do
      ministry = create(:ministry)
      person = create(:person)
      assignment = create(:assignment, person: person, ministry: ministry,
                                       role: "leader")
      person_relationship = {
        "person" => person.gr_id, "relationship_entity_id" => assignment.gr_id,
        "team_role" => "admin", "created_by" => ENV["GLOBAL_REGISTRY_SYSTEM_ID"],
      }

      GrSync::AssignmentPull.new(ministry, person_relationship).sync

      expect(assignment.reload.role).to eq "admin"
    end

    it "does not update existing assignment if missing team_role" do
      ministry = create(:ministry)
      person = create(:person)
      assignment = create(:assignment, person: person, ministry: ministry,
                                       role: "leader")
      person_relationship = {
        "person" => person.gr_id, "relationship_entity_id" => assignment.gr_id,
        "created_by" => ENV["GLOBAL_REGISTRY_SYSTEM_ID"],
      }

      GrSync::AssignmentPull.new(ministry, person_relationship).sync

      expect(assignment.reload.role).to eq "leader"
    end

    it "does not update existing assignment if missing created by different system" do
      ministry = create(:ministry)
      person = create(:person)
      assignment = create(:assignment, person: person, ministry: ministry,
                                       role: "leader")
      person_relationship = {
        "person" => person.gr_id, "relationship_entity_id" => assignment.gr_id,
        "created_by" => SecureRandom.uuid, "team_role" => "member",
      }

      GrSync::AssignmentPull.new(ministry, person_relationship).sync

      expect(assignment.reload.role).to eq "leader"
    end

    it "creates a new assignment if one is missing" do
      ministry = create(:ministry)
      person_gr_id = SecureRandom.uuid
      assignment_gr_id = SecureRandom.uuid
      person = create(:person)
      allow(Person).to receive(:person_for_gr_id) { person }
      person_relationship = {
        "person" => person_gr_id, "relationship_entity_id" => assignment_gr_id,
        "team_role" => "leader", "created_by" => ENV["GLOBAL_REGISTRY_SYSTEM_ID"],
      }

      expect {
        GrSync::AssignmentPull.new(ministry, person_relationship).sync
      }.to change(Assignment, :count).by(1)

      expect(Person).to have_received(:person_for_gr_id).with(person_gr_id)
      assignment = Assignment.last
      expect(assignment.person).to eq person
      expect(assignment.ministry).to eq ministry
      expect(assignment.role).to eq "leader"
      expect(assignment.gr_id).to eq assignment_gr_id
    end

    it "does not creates a new assignment if one is missing and it was created by another system" do
      ministry = create(:ministry)
      person_gr_id = SecureRandom.uuid
      assignment_gr_id = SecureRandom.uuid
      person_relationship = {
        "person" => person_gr_id, "relationship_entity_id" => assignment_gr_id,
        "team_role" => "leader", "created_by" => SecureRandom.uuid,
      }

      expect {
        GrSync::AssignmentPull.new(ministry, person_relationship).sync
      }.to_not change(Assignment, :count)
    end

    describe "handling multiple GR assignments for person and ministry" do
      it "replaces an existing assignment if relationship has higher role level" do
        ministry = create(:ministry)
        person = create(:person)
        assignment = create(:assignment, ministry: ministry, person: person,
                                         role: Assignment.roles[:self_assigned])
        new_gr_id = SecureRandom.uuid
        person_relationship = {
          "person" => person.gr_id, "relationship_entity_id" => new_gr_id,
          "team_role" => "leader", "created_by" => ENV["GLOBAL_REGISTRY_SYSTEM_ID"],
        }

        expect {
          GrSync::AssignmentPull.new(ministry, person_relationship).sync
        }.to_not change(Assignment, :count)

        expect(assignment.reload.gr_id).to eq new_gr_id
        expect(assignment.role).to eq "leader"
      end

      it "leaves existing assignment if relationship has lower role level" do
        ministry = create(:ministry)
        person = create(:person)
        assignment = create(:assignment, ministry: ministry, person: person,
                                         role: Assignment.roles[:leader])
        original_assignment_gr_id = assignment.gr_id
        new_gr_id = SecureRandom.uuid
        person_relationship = {
          "person" => person.gr_id, "relationship_entity_id" => new_gr_id,
          "team_role" => "self_assigned", "created_by" => ENV["GLOBAL_REGISTRY_SYSTEM_ID"],
        }

        expect {
          GrSync::AssignmentPull.new(ministry, person_relationship).sync
        }.to_not change(Assignment, :count)

        expect(assignment.reload.gr_id).to eq original_assignment_gr_id
        expect(assignment.role).to eq "leader"
      end
    end
  end
end
