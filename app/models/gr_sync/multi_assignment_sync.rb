# frozen_string_literal: true

module GrSync
  class MultiAssignmentSync
    def initialize(ministry, entity)
      @ministry = ministry
      @entity = entity
    end

    def sync
      relationship = @entity.dig("person:relationship")
      return unless relationship.present?
      # relationship will only be an array if there is more than one
      Array.wrap(relationship).each(&method(:sync_relationship))
    end

    private

    def sync_relationship(relationship)
      AssignmentPull.new(@ministry, relationship).sync
    end
  end
end
