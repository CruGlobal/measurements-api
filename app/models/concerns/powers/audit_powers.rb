# frozen_string_literal: true
module Powers
  module AuditPowers
    extend ActiveSupport::Concern

    included do
      # Power definitions
      power :audits do
        Audit.where(ministry: inherited_assignment.ministry) if inherited_assignment.try(:approved_role?)
      end
    end
  end
end
