class UserMapView < ActiveRecord::Base
  belongs_to :person, foreign_key: :person_id
end
