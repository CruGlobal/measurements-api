class Power
  include Consul::Power

  def initialize(user)
    @user = user
  end

  power :assignments do
    nil
  end
end
