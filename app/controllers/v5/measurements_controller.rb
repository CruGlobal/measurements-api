# frozen_string_literal: true

module V5
  class MeasurementsController < V5::BaseUserController
    include V5::MeasurementsConcern[authorize: true]
  end
end
