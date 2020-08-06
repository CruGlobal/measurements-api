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

    def attributes(requested_attrs = nil, reload = false)
      # Remove nil values
      super(requested_attrs, reload).reject { |_k, v| v.nil? }
    end

    def custom?
      object.perm_link.sub("lmi_total_", "").starts_with?("custom_")
    end

    def locale
      object.locale(scope[:locale], scope[:ministry])
    end

    def localized_name
      object.localized_name(scope[:locale], scope[:ministry])
    end

    def localized_description
      object.localized_description(scope[:locale], scope[:ministry])
    end

    def measurement_type_ids
      type_ids = {}
      type_ids["total"] = object.total_id if object.total.present?
      type_ids["local"] = object.local_id if object.local.present?
      type_ids["person"] = object.person_id if object.person.present?
      type_ids
    end
  end
end
