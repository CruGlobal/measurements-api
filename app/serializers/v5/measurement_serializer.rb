# frozen_string_literal: true
module V5
  class MeasurementSerializer < ActiveModel::Serializer
    attributes :column,
               :description,
               :leader_only,
               :locale,
               :localized_description,
               :localized_name,
               :measurement_type_ids,
               :perm_link,
               :perm_link_stub,
               :section,
               :sort_order,
               :supported_staff_only,
               :total,
               :local,
               :person

    attribute :custom?, key: :is_custom
    attribute :english, key: :name

    def custom?
      object.perm_link.sub('lmi_total_', '').starts_with?('custom_')
    end

    def locale
      object.locale(scope[:locale], scope[:ministry_id])
    end

    def localized_name
      object.localized_name(scope[:locale], scope[:ministry_id])
    end

    def localized_description
      object.localized_description(scope[:locale], scope[:ministry_id])
    end

    def measurement_type_ids
      {
        total: object.total_id,
        local: object.local_id,
        person: object.person_id
      }
    end
  end
end
