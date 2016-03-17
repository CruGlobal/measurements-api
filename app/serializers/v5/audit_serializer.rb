module V5
  class AuditSerializer < ActiveModel::Serializer
    attributes :timestamp, :message, :type, :person_id, :ministry_id, :ministry_name

    def type
      object.audit_type.upcase
    end

    def timestamp
      object.created_at.strftime('%Y-%m-%d')
    end

    def person_id
      object.person.gr_id
    end

    def ministry_id
      object.ministry.gr_id
    end
  end
end
