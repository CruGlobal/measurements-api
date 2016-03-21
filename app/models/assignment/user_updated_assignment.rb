# Allows you to decorate an Assignment instance to indicate that it has been
# changed by a user and so should be synced to global registry.
class Assignment
  class UserUpdatedAssignment < SimpleDelegator
    def save
      save_succeeded = __getobj__.save
      update_gr_relationship if save_succeeded
      save_succeeded
    end

    private

    def update_gr_relationship
      root_gr_client.put(gr_id, entity: { ministry_membership: { team_role: role } })
    end

    def root_gr_client
      GlobalRegistry::Entity.new
    end
  end
end
