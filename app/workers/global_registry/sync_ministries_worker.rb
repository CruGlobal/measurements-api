module GlobalRegistry
  class SyncMinistriesWorker
    include Sidekiq::Worker
    sidekiq_options unique: :until_and_while_executing, retry: false

    def perform
      # Fetches all Ministries from GR and either inserts or updates
      ::Ministry.all_gr_ministries do |entity|
        ::Ministry.ministry entity[:id], true
      end
    end
  end
end
