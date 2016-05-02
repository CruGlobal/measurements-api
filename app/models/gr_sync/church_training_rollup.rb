# frozen_string_literal: true
module GrSync
  class ChurchTrainingRollup
    def initialize(gr_client)
      @gr_client ||= gr_client
    end

    def rollup_all
      # Queue up rollup processes
      GrSync::WithGrWorker.queue_call_with_root(GrSync::Rollup::ChurchesRollup, :rollup)
      GrSync::WithGrWorker.queue_call_with_root(GrSync::Rollup::EngagedRollup, :rollup)
      GrSync::WithGrWorker.queue_call_with_root(GrSync::Rollup::GroupsRollup, :rollup)
      GrSync::WithGrWorker.queue_call_with_root(GrSync::Rollup::MovementsRollup, :rollup)
      GrSync::WithGrWorker.queue_call_with_root(GrSync::Rollup::MultiplyingRollup, :rollup)
      # GrSync::WithGrWorker.queue_call_with_root(GrSync::Rollup::TrainingRollup, :rollup)
    end
  end
end
