# frozen_string_literal: true
class MeasurementTranslation < ApplicationRecord
  belongs_to :measurement
  belongs_to :ministry
end
