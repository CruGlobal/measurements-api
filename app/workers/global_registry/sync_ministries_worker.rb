module GlobalRegistry
  class SyncMinistriesWorker
    include Sidekiq::Worker
    sidekiq_options unique: :until_and_while_executing, retry: false

    def perform
      GlobalRegistry::Ministry.all do |gr_ministry|
        ::Ministry.ministry(gr_ministry.id, true)
      end
    end
  end
end
