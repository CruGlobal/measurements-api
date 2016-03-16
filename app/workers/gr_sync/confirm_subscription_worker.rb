module GrSync
  class ConfirmSubscriptionWorker
    include Sidekiq::Worker
    sidekiq_options retry: true

    def perform(confirmation_url)
      RestClient.get(confirmation_url)
    end
  end
end
