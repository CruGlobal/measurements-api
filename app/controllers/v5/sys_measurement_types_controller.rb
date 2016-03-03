module V5
  class SysMeasurementTypesController < V5::MeasurementTypesController
    include V5::BaseSystemsController

    private

    def measurement_type_params
      permitted = params.permit([:english, :perm_link_stub, :description, :section, :column,
                                 :sort_order, :parent_id, :localized_name, :localized_description,
                                 :ministry_id, :locale, :is_core])
      permitted[:ministry_id] = ministry.id if params[:ministry_id]
      permitted
    end
  end
end
