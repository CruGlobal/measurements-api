class MinistryArea < ActiveRecord::Base
  belongs_to :ministry
  belongs_to :area
  belongs_to :created_by, class_name: 'Person'
end
