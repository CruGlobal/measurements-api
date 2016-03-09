module GlobalRegistry
  class BaseWorker
    include Sidekiq::Worker

    def perform(global_registry_params = {})
      GlobalRegistryClient.parameters = global_registry_params
      perform_with_gr
      GlobalRegistryClient.parameters = nil
    end

    def perform_with_gr
      raise 'Sub-classes must implement'
    end
  end
end
