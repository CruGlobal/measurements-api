class UserContentLocale < ActiveRecord::Base
  belongs_to :person
  belongs_to :ministry
end
