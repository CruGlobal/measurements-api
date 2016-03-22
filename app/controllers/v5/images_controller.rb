# frozen_string_literal: true
module V5
  class ImagesController < V5::BaseUserController
    power :stories, map: {
      [:create] => :update_stories
    }, as: :story_scope

    def create
      render_error('Invalid story id') and return unless load_story
      render_image if update_image
    end

    private

    def load_story
      @story ||= story_scope.find_by(id: params[:story_id])
    end

    def render_image
      render json: @story, status: :created, serializer: StoryImageSerializer
    end

    def update_image
      @story.update(image: image_params) if image_params
    end

    def image_params
      post_params.require('image-file')
    end

    def request_power
      ministry_id = if params[:action].to_sym == :create
                      Story.find_by(id: params[:story_id]).try(:ministry).try(:gr_id)
                    end
      Power.new(current_user, ministry_id)
    end
  end
end
