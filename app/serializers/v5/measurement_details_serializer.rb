# frozen_string_literal: true
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
      types = { total: object.measurement.total_id }
      types[:local] = object.measurement.local_id if object.local.any? { |_k, v| v.to_i > 0 }
      types[:person] = object.measurement.person_id if any_my_measurements?
      types
    end

    private

    def any_my_measurements?
      object.my_measurements && object.my_measurements.any? { |_k, v| v.to_i > 0 }
    end
  end
end
