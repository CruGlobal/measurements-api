module ActiveModel
  module SerializerExtension
    module ModelName
      def json_key
        root || _type ||
          begin
            if object.class.respond_to?(:model_name)
              object.class.model_name.to_s.underscore
            elsif object.respond_to?(:first) && object.first.respond_to?(:model_name)
              object.first.class.model_name.to_s.underscore
            end
          rescue ArgumentError
            'anonymous_object'
          end
      end
    end
  end
end
