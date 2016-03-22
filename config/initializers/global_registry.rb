# frozen_string_literal: true
require 'global_registry'

GlobalRegistry.configure do |config|
  config.access_token = ENV['GLOBAL_REGISTRY_TOKEN']
  config.base_url = ENV['GLOBAL_REGISTRY_URL']
end
