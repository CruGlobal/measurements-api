module GrSync
  class NotificationWorker
    include Sidekiq::Worker

    def perform(_notification)
    end
  end
end
