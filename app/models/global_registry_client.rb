class GlobalRegistryClient
  def self.thread_key
    [to_s, 'parameters'].join('.')
  end

  def self.parameters
    Thread.current.thread_variable_get(thread_key) || {}
  end

  def self.parameters=(params = {})
    Thread.current.thread_variable_set(thread_key, params)
  end

  def self.client(type = :entity)
    klass = "GlobalRegistry::#{type.to_s.camelize}".constantize
    klass.new(parameters)
  end
end
