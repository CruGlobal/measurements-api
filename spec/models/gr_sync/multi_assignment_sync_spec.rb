# frozen_string_literal: true

require "rails_helper"

describe GrSync::MultiAssignmentSync, "#sync" do
  it "does nothing if there is no person:relationship in the entity" do
    ministry = double
    empty_entity = {}
    allow(GrSync::AssignmentPull).to receive(:new)

    GrSync::MultiAssignmentSync.new(ministry, empty_entity).sync

    expect(GrSync::AssignmentPull).to_not have_received(:new)
  end

  it "syncs each assignment for the person:relationship entries" do
    ministry = double
    entity = {
      "person:relationship" => [{person: "1"}, {person: "2"}],
    }
    assignment_sync1 = double(sync: nil)
    assignment_sync2 = double(sync: nil)
    allow(GrSync::AssignmentPull).to receive(:new)
      .and_return(assignment_sync1, assignment_sync2)

    GrSync::MultiAssignmentSync.new(ministry, entity).sync

    expect(GrSync::AssignmentPull).to have_received(:new).with(ministry, person: "1")
    expect(GrSync::AssignmentPull).to have_received(:new).with(ministry, person: "2")
    expect(assignment_sync1).to have_received(:sync)
    expect(assignment_sync2).to have_received(:sync)
  end

  it "works for a single person:relationship not in an array" do
    ministry = double
    entity = {"person:relationship" => {person: "1"}}
    assignment_sync = double(sync: nil)
    allow(GrSync::AssignmentPull).to receive(:new) { assignment_sync }

    GrSync::MultiAssignmentSync.new(ministry, entity).sync

    expect(GrSync::AssignmentPull).to have_received(:new).with(ministry, person: "1")
    expect(assignment_sync).to have_received(:sync)
  end
end
