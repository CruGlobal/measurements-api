module V5
  class MinistrySubMinistrySerializer < ActiveModel::Serializer
    attributes :min_id, :name, :min_code

    def min_id
      object.gr_id
    end
  end
end
