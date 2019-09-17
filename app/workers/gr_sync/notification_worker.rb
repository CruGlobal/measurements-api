# frozen_string_literal: true

module GrSync
  class NotificationWorker
    include Sidekiq::Worker

    def perform(notification)
      if notification["action"] == "merge"
        merge_notification(notification)
      else
        change_notification(notification)
      end
    end

    private

    def merge_notification(notification)
      winner_id = notification["new_id"] || notification["winner"]["id"]
      loser_id = notification["old_id"] || notification["loser"]["id"]
      handler = MergeNotificationHandler.new(winner_id, loser_id)
      if notification["new_id"].present?
        handler.merge_success_notification
      else
        handler.merge_conflict_notification
      end
    end

    def change_notification(notification)
      ChangeNotificationHandler
        .new(notification["entity_type"], notification["id"])
        .public_send("#{notification["action"]}_notification")
    end
  end
end
