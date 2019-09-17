# frozen_string_literal: true

module V5
  class TrainingSerializer < ActiveModel::Serializer
    attributes :id,
               :ministry_id,
               :name,
               :date,
               :type,
               :mcc,
               :latitude,
               :longitude,
               :last_updated,
               :created_by,
               :created_by_email

    has_many :completions, key: :gcm_training_completions, serializer: TrainingCompletionSerializer

    def ministry_id
      object.ministry.gr_id
    end

    def date
      object.date.strftime("%Y-%m-%d")
    end

    def last_updated
      object.updated_at.strftime("%Y-%m-%d")
    end

    def created_by
      object.created_by.try(:gr_id)
    end

    def created_by_email
      object.created_by.try(:cas_username) || object.created_by.try(:email)
    end
  end
end
