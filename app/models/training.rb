class Training < ActiveRecord::Base
  belongs_to :ministry
  authorize_values_for :ministry

  belongs_to :created_by, class_name: 'Person'

  validates :name, presence: { message: "Could not find required field: 'name'" }
  validates :ministry, presence: { message: "Could not find required field: 'ministry_id'" }
  validates :type, inclusion: { in: ['MC2', 'T4T', 'CPMI', ''], message: "Training type is not recognized: '%{value}'" }
  validates :mcc, presence: { message: "Could not find required field: 'mcc'" }
  validates :date, presence: { message: "Could not find required field: 'date'" }

  has_many :completions, dependent: :destroy, class_name: 'TrainingCompletion'
end
