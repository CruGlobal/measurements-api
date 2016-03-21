module V5
  class StoryArraySerializer < PaginatedSerializer
    has_many :stories, serializer: V5::StorySerializer do
      object
    end
  end
end
