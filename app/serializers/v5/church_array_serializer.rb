module V5
  class ChurchArraySerializer
    def self.serializer_for(resource)
      if resource.is_a? Church
        ChurchSerializer
      else # its an Array
        ChurchClusterSerializer
      end
    end
  end
end
