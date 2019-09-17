# frozen_string_literal: true

require "rails_helper"

describe GrSync::MergeNotificationHandler do
  context "#merge_success_notification" do
    it "raises an exception because it's not implemented yet" do
      expect {
        GrSync::MergeNotificationHandler.new("1", "2").merge_success_notification
      }.to raise_error(/not implemented/)
    end
  end

  context "#merge_conflict_notification" do
    it "raises an exception because it's not implemented yet" do
      expect {
        GrSync::MergeNotificationHandler.new("1", "2").merge_conflict_notification
      }.to raise_error(/not implemented/)
    end
  end
end
