# frozen_string_literal: true

module V5
  class SystemsMeasurementsController < V5::BaseUserController
    include V5::MeasurementsConcern[authorize: false]
    include V5::BaseSystemsController
  end
end
