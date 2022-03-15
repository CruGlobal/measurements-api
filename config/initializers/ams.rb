# frozen_string_literal: true

# ActiveModel::Serializer.config

require "active_model/serializer_extension/model_name"
Rails.application.config.to_prepare do
  ActiveModel::Serializer.prepend ActiveModel::SerializerExtension::ModelName
end
