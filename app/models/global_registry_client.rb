# frozen_string_literal: true
# There are two ways to use the GlobalRegistry client class:
#
# 1. As a thread-global store of the global registry config. To do that, assign
#      GlobalRegistryClient.parameters = { access_token: 'abc' }
#   Then to access a new global registry client instance for a particular type
#   of entity, call e.g.
#      client = GlobalRegistryClient.client(:entity)
#      client.put(..)
#
# 2. As a particular instance representing the global registry config which can
#    then be passed into classes that use it to communicate with the global
#    registry, e.g.:
#       client = GlobalRegistryClient.new(access_token: 'abc')
#    To access a client intstance for a particular type of config, you would
#    call a method on the overall client instance, e.g.
#       entity_client = client.entity
#       entity_client.put
#    You could use a plural as in `client.entities.get(..)` which would have the
#    same effect as `client.entity.get(..)`.
class GlobalRegistryClient
  attr_reader :parameters

  # Use the root global registry key by default
  def initialize(parameters = {})
    @parameters = parameters
  end

  def method_missing(method_name, *_args, &_block)
    klass_name = "GlobalRegistry::#{method_name.to_s.singularize.camelize}"
    klass_name.constantize.new(@parameters)
  end

  class << self
    def thread_key
      [to_s, 'parameters'].join('.')
    end

    def parameters
      Thread.current.thread_variable_get(thread_key) || {}
    end

    def parameters=(params = {})
      Thread.current.thread_variable_set(thread_key, params)
    end

    def client(type = :entity)
      klass = "GlobalRegistry::#{type.to_s.camelize}".constantize
      klass.new(parameters)
    end
  end
end
