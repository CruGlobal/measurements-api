# frozen_string_literal: true

require "spec_helper"

describe Assignment::UserUpdatedAssignment do
  context "#save" do
    # The details of the sync request to global registry are covered in the
    # integration specs for the assignments controller, so here just do a check
    # that it only does the sync for a successful save.

    it "does not sync to global registry if the save did not succeed" do
      assignment = double(save: false)
      gr_client = double(put: nil)
      allow(GlobalRegistry::Entity).to receive(:new) { gr_client }

      Assignment::UserUpdatedAssignment.new(assignment).save

      expect(gr_client).to_not have_received(:put)
    end

    it "syncs to global registry if the save succeeded" do
      assignment = double(save: true, gr_id: "1", role: "r")
      gr_client = double(put: nil)
      allow(GlobalRegistry::Entity).to receive(:new) { gr_client }

      Assignment::UserUpdatedAssignment.new(assignment).save

      expect(gr_client).to have_received(:put)
    end
  end
end
