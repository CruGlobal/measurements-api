module V5
  class WhqMinistrySerializer < ActiveModel::Serializer
    attributes :ministry_id, :name, :area_code, :min_code, :area_name

    def attributes(requested_attrs = nil, reload = false)
      # Remove nil values
      super.reject { |_k, v| v.nil? }
    end

    def ministry_id
      object.gr_id
    end

    def area_code
      object.area.try(:code)
    end

    def area_name
      object.area.try(:name)
    end
  end
end
