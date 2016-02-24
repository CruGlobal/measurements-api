class Measurement < ActiveRecord::Base
  belongs_to :parent, class_name: 'Measurement'
end
