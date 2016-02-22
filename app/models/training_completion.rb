class TrainingCompletion < ActiveRecord::Base
  belongs_to :training
  validates :training, presence: { message: "Could not find required field: 'training_id'" }
end
