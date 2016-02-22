module V5
  class TrainingSerializer < ActiveModel::Serializer
    attributes :id, :id, :ministry_id, :name, :date, :type, :mcc, :latitude, :longitude

    has_many :completions, key: :gcm_training_completions

    def ministry_id
      object.ministry.gr_id
    end

    def date
      object.date.strftime('%Y-%m-%d')
    end
  end
end
