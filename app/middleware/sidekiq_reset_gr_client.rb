# frozen_string_literal: true

class SidekiqResetGrClient
  def call(_worker, _job, _queue)
    # The GlobalRegistryClient uses a thread store so reset it before every
    # Sidekiq worker call that it's always in a consistent starting state even
    # if a worker errors and a thread gets reused by another worker.
    GlobalRegistryClient.parameters = nil
    yield
  end
end
