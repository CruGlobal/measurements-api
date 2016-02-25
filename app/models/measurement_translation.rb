class MeasurementTranslation < ActiveRecord::Base
  belongs_to :measurement
  belongs_to :ministry
end
