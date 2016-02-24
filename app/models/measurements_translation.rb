class MeasurementsTranslation < ActiveRecord::Base
  belongs_to :measurement
  belongs_to :ministry
end
