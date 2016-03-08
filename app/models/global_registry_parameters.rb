class GlobalRegistryParameters
  def self.thread_key
    to_s
  end

  def self.current
    Thread.current.thread_variable_get(thread_key) || {}
  end

  def self.current=(params = {})
    Thread.current.thread_variable_set(thread_key, params)
  end
end
