module V5
  class MeasurementDetailsSerializer < ActiveModel::Serializer
    ATTRS = [:perm_link_stub,
             :measurement_type_ids,
             :total,
             :local_breakdown,
             :local,
             :self_breakdown,
             :my_measurements,
             :sub_ministries,
             :team,
             :self_assigned,
             :split_measurements].freeze
    attributes ATTRS
    delegate(*ATTRS, to: :object)

    def measurement_type_ids
      {
        total: object.measurement.total_id,
        local: object.measurement.local_id,
        person: object.measurement.person_id
      }
    end
  end
end
