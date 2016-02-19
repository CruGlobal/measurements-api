class Training < ActiveRecord::Base
  belongs_to :ministry
  belongs_to :created_by, class_name: 'Person'

  # has_many :completions
  def completions
    [] # stubbed for now
  end
end
