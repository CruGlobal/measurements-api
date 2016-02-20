module V5
  class TrainingSerializer < ActiveModel::Serializer
    attributes :id, :id, :ministry_id, :name, :date, :type, :mcc, :latitude, :longitude

    has_many :gcm_training_completions

    def gcm_training_completions
      object.completions
    end

    def ministry_id
      object.ministry.gr_id
    end

    def date
      object.date.strftime('%Y-%m-%d')
    end
  end
end
