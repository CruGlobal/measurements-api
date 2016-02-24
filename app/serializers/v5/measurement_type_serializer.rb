module V5
  class MeasurementTypeSerializer < ActiveModel::Serializer
    attributes :perm_link_stub,
               :perm_link,
               :is_custom,
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
  end
end
