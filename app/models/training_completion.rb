class TrainingCompletion < ActiveRecord::Base
  belongs_to :training
  validates :training, presence: { message: "Could not find required field: 'training_id'" }
  attr_readonly :training_id

  validates :phase, presence: { message: "Could not find required field: 'phase'" }
  validates :number_completed, presence: { message: "Could not find required field: 'number_completed'" },
                               numericality: { greater_than: 0, message: 'cannot be negative' }
  validates :date, presence: { message: "Could not find required field: 'date'" }
end
