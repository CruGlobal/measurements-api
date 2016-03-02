class SystemAccessToken
  def self.thread_key
    to_s
  end

  def self.current
    Thread.current.thread_variable_get(thread_key)
  end

  def self.current=(token)
    Thread.current.thread_variable_set(thread_key, token)
  end
end
