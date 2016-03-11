class Story < ActiveRecord::Base
  belongs_to :church
  belongs_to :training
end
