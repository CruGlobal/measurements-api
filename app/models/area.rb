class Area < ActiveRecord::Base
  has_many :ministry_areas
  has_many :ministries, through: :ministry_areas
end
