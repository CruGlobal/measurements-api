module V5
  class StorySerializer < ActiveModel::Serializer
    attributes :story_id,
               :title,
               :content,
               :image_url,
               :video_url,
               :created_by,
               :ministry_id,
               :church_id,
               :training_id,
               :mcc,
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
      object.image.file.try(:exists?) ? object.image.url : object.image_url
    end

    def created_by
      object.created_by.try(:gr_id)
    end

    def ministry_id
      object.ministry.try(:gr_id)
    end

    def location
      { latitude: object.latitude, longitude: object.longitude }
    end

    def privacy
      case object.privacy.to_sym
      when :everyone
        'public'
      when :team_only
        'team_only'
      end
    end

    def created_at
      object.created_at.strftime('%Y-%m-%d')
    end

    def updated_at
      object.updated_at.strftime('%Y-%m-%d')
    end
  end
end
