module V5
  class StoryImageSerializer < ActiveModel::Serializer
    attributes :story_id,
               :image_url

    def story_id
      object.id
    end
  end
end
