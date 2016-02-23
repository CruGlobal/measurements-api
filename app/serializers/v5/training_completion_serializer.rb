module V5
  class TrainingCompletionSerializer < ActiveModel::Serializer
    attributes :id, :phase, :number_completed, :date, :training_id

    def date
      object.date.strftime('%Y-%m-%d')
    end
  end
end
