SIDEKIQ_CRON_HASH = {
  'Setup global registry subscriptions' => {
    'cron'  => '0 3 * * *',
    'class' => 'GrSync::SetupSubscriptionsWorker',
    'args'  => []
  },
  'Sync ministries' => {
    'cron' => '0 4 * * *',
    'class' => 'GrSync::WithGrWorker',
    'args' => [{}, 'GrSync::MinistriesSync', 'sync_all']
  }
}.freeze

unless Rails.env.development? || Rails.env.test?
  Sidekiq::Cron::Job.load_from_hash!(SIDEKIQ_CRON_HASH)
end
