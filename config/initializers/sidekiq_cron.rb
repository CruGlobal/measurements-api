SIDEKIQ_CRON_HASH = {
  'Setup global registry subscriptions' => {
    'class' => 'GrSync::SetupSubscriptionsWorker',
    'cron'  => '0 3 * * *',
    'args'  => []
  }
}.freeze

unless Rails.env.development? || Rails.env.test?
  Sidekiq::Cron::Job.load_from_hash!(SIDEKIQ_CRON_HASH)
end
