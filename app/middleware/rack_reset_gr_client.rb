# frozen_string_literal: true

class RackResetGrClient
  def initialize(app)
    @app = app
  end

  def call(env)
    # The GlobalRegistryClient uses a thread store so reset it before every HTTP
    # call so that it's always in a consistent starting state even if a call
    # errors and a thread gets reused.
    GlobalRegistryClient.parameters = nil
    @app.call(env)
  end
end
