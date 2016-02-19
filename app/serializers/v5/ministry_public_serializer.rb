module V5
  class MinistryPublicSerializer < ActiveModel::Serializer
    attributes :ministry_id, :name

    def ministry_id
      object.gr_id
    end
  end
end
