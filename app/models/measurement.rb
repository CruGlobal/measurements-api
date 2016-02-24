class Measurement < ActiveRecord::Base
  belongs_to :parent, class_name: 'Measurement'
  has_many :measurements_translations
end
