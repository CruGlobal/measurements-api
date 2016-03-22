# frozen_string_literal: true
module GrSync
  class AssignmentSync
    def initialize(ministry, person_relationship)
      @ministry = ministry
      @person_relationship = person_relationship
    end

    def sync
    end

    private

    def gr_client
      # Always use the root global registry key for syncing assignments
      @gr_client ||= GlobalRegistryClient.new
    end
  end
end
