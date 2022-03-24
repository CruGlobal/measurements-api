# frozen_string_literal: true

module V5
  class ChurchArraySerializer
    def self.serializer_for(resource, options = {})
      if resource.is_a? Church
        ChurchSerializer
      else # its an Array
        ChurchClusterSerializer
      end
    end
  end
end
