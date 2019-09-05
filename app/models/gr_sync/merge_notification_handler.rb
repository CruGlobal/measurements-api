# frozen_string_literal: true

module GrSync
  class MergeNotificationHandler
    def initialize(winner_entity_id, loser_entity_id)
      @winner_gr_id = winner_entity_id
      @loser_gr_id = loser_entity_id
    end

    def merge_success_notification
      # We should update the winner and destory the loser but we would need to
      # also merge all the child records too.
      raise "Merge success notification not implemented yet."
    end

    def merge_conflict_notification
      # Not sure what to do here yet
      raise "Merge conflict notification not implemented yet."
    end
  end
end
