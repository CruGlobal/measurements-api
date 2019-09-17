# frozen_string_literal: true

class Ministry
  class UserUpdatedMinistry < SimpleDelegator
    def save
      success = super
      async_update_entity if success
      success
    end
  end
end
