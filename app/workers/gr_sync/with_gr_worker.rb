# frozen_string_literal: true

module GrSync
  class WithGrWorker
    include Sidekiq::Worker
    sidekiq_options retry: false

    def self.queue_call(gr_client_params, klass, method, *args)
      perform_async(gr_client_params.deep_stringify_keys, klass.name, method.to_s, *args)
    end

    def self.queue_call_with_root(klass, method, *args)
      queue_call({}, klass, method, *args)
    end

    def perform(gr_client_params, klass_name, method, *args)
      # For concern isolation and security purposes, only allow calling methods
      # on classes in the GrSync namespace.
      raise "#{klass_name} not in GrSync::" unless klass_name.to_s.start_with?("GrSync::")

      gr_client = GlobalRegistryClient.new(gr_client_params)
      klass_name.constantize.new(gr_client).public_send(method, *args)
    end
  end
end
