# frozen_string_literal: true

SIDEKIQ_CRON_HASH = {
  "Setup global registry subscriptions" => {
    "cron" => "0 3 * * *",
    "class" => "GrSync::SetupSubscriptionsWorker",
    "args" => [],
  },
  "Sync ministries" => {
    "cron" => "0 4 * * *",
    "class" => "GrSync::WithGrWorker",
    "args" => [{}, "GrSync::MinistriesSync", "sync_all"],
  },
  "Church - Training Rollup" => {
    "cron" => "30 1 * * *",
    "class" => "GrSync::WithGrWorker",
    "args" => [{}, "GrSync::ChurchTrainingRollup", "rollup_all"],
  },
}.freeze

unless Rails.env.development? || Rails.env.test?
  Sidekiq::Cron::Job.load_from_hash!(SIDEKIQ_CRON_HASH)
end
