# frozen_string_literal: true
module V5
  class AuditArraySerializer < PaginatedSerializer
    has_many :entries, serializer: V5::AuditSerializer do
      object
    end
  end
end
