# frozen_string_literal: true
module Powers
  module AuditPowers
    extend ActiveSupport::Concern

    included do
      # Power definitions
      power :audits do
        Audit.where(ministry: ministry) if assignment.try(:approved_role?) || inherited_assignment.try(:approved_role?)
      end
    end
  end
end
