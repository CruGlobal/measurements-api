module GlobalRegistry
  class BaseWorker
    include Sidekiq::Worker

    def perform(global_registry_params = {})
      GlobalRegistryParameters.current = global_registry_params
      perform_with_gr
      GlobalRegistryParameters.current = nil
    end

    def perform_with_gr
      raise 'Sub-classes must implement'
    end
  end
end
