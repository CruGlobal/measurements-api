# frozen_string_literal: true
class ApiError < ActiveModelSerializers::Model
  attr_accessor :message, :options
end
