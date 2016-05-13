# frozen_string_literal: true
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

    delegate :locale, :measurement, to: :object
    delegate :id, :perm_link, :person_id, :local_id, :total_id, :leader_only,
             :supported_staff_only, :perm_link_stub,
             to: :measurement

    def attributes(args)
      # Remove nil values
      super(args).reject { |_k, v| v.nil? }
    end

    def custom?
      perm_link.sub('lmi_total_', '').starts_with?('custom_')
    end

    def localized_name
      object.localized_name || object.english
    end

    def localized_description
      object.localized_description || object.description
    end
  end
end
