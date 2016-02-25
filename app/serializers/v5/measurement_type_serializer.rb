module V5
  class MeasurementTypeSerializer < ActiveModel::Serializer
    attributes :perm_link_stub,
               :perm_link,
               :english,
               :description,
               :section,
               :column,
               :sort_order,
               :total_id,
               :local_id,
               :person_id,
               :leader_only,
               :supported_staff_only,
               :id,
               :localized_name,
               :localized_description,
               :locale,
               :parent_id

    attribute :custom?, key: :is_custom

    def custom?
      object.perm_link.sub('lmi_total_', '').starts_with?('custom_')
    end

    def localized_name
      object.localized_name(scope[:locale], scope[:ministry_id])
    end

    def localized_description
      object.localized_description(scope[:locale], scope[:ministry_id])
    end

    def locale
      if object.measurement_translations.where(language: scope[:locale], ministry: scope[:ministry]).any?
        scope[:locale]
      else
        'en'
      end
    end
  end
end
