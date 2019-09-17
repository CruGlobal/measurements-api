# frozen_string_literal: true

module V5
  class StorySerializer < ActiveModel::Serializer
    attributes :story_id,
               :title,
               :content,
               :image_url,
               :video_url,
               :created_by,
               :created_name,
               :ministry_id,
               :ministry_name,
               :church_id,
               :church_name,
               :training_id,
               :training_name,
               :mcc,
               :language,
               :location,
               :privacy,
               :state,
               :created_at,
               :updated_at

    def attributes(args)
      # Remove nil values
      super(args).reject { |_k, v| v.nil? }
    end

    def story_id
      object.id
    end

    def image_url
      object.image.file.try(:exists?) ? object.image.url : object.user_image_url
    end

    def created_by
      object.created_by.try(:gr_id)
    end

    def created_name
      object.created_by.try(:full_name)
    end

    def ministry_id
      object.ministry.try(:gr_id)
    end

    def ministry_name
      object.ministry.try(:name)
    end

    def church_name
      object.church.try(:name)
    end

    def training_name
      object.training.try(:name)
    end

    def location
      return nil unless object.latitude.present? && object.longitude.present?
      {latitude: object.latitude, longitude: object.longitude}
    end

    def privacy
      case object.privacy.to_sym
      when :everyone
        "public"
      when :team_only
        "team_only"
      end
    end

    def created_at
      object.created_at.strftime("%Y-%m-%d")
    end

    def updated_at
      object.updated_at.strftime("%Y-%m-%d")
    end
  end
end
