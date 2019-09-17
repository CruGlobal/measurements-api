# frozen_string_literal: true

require "rails_helper"

describe GrSync::NotificationWorker, "#perform" do
  describe "sending change notifications to handler" do
    it "sends created" do
      expect_change_notification_handled("created", :created_notification)
    end
    it "sends updated" do
      expect_change_notification_handled("updated", :updated_notification)
    end
    it "sends deleted" do
      expect_change_notification_handled("deleted", :deleted_notification)
    end

    def expect_change_notification_handled(action, expected_method)
      notification = {
        "entity_type" => "person", "id" => "1f", "action" => action,
      }
      handler = double(expected_method => nil)
      allow(GrSync::ChangeNotificationHandler).to receive(:new) { handler }

      GrSync::NotificationWorker.new.perform(notification)

      expect(GrSync::ChangeNotificationHandler)
        .to have_received(:new).with("person", "1f")
      expect(handler).to have_received(expected_method)
    end
  end

  describe "sending merge notifications to handler" do
    it "sends merge success notifications to merge handler" do
      notification = {
        "action" => "merge", "new_id" => "1a", "old_id" => "1b",
      }
      handler = double(merge_success_notification: nil)
      allow(GrSync::MergeNotificationHandler).to receive(:new) { handler }

      GrSync::NotificationWorker.new.perform(notification)

      expect(GrSync::MergeNotificationHandler).to have_received(:new).with("1a", "1b")
      expect(handler).to have_received(:merge_success_notification)
    end

    it "sends merge conflict notifications to merge handler" do
      notification = {
        "action" => "merge",
        "winner" => {"id" => "1a"}, "loser" => {"id" => "1b"},
      }
      handler = double(merge_conflict_notification: nil)
      allow(GrSync::MergeNotificationHandler).to receive(:new) { handler }

      GrSync::NotificationWorker.new.perform(notification)

      expect(GrSync::MergeNotificationHandler).to have_received(:new).with("1a", "1b")
      expect(handler).to have_received(:merge_conflict_notification)
    end
  end
end
