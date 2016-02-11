module V5
  class ChurchArraySerializer < ActiveModel::Serializer::CollectionSerializer
    def self.serializer_for(resource)
      if resource.is_a? Church
        ChurchSerializer
      else
        ChurchClusterSerializer
      end
    end
  end
end
