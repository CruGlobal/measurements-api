module V5
  class StoriesController < V5::BaseUserController
    power :stories, map: {
      [:show] => :show_stories,
      [:update] => :update_stories,
      [:create] => :create_story
    }, as: :story_scope

    def index
      load_stories
      render_stories
    end

    def show
      load_story or render_not_found
      render_story
    end

    def create
      if build_story
        render_story :created
      else
        render_errors
      end
    end

    def update
      load_story or render_error('Invalid story id') && return
      if build_story
        render_story
      else
        render_errors
      end
    end

    private

    def load_story
      @story ||= story_scope.find_by(id: params[:id])
    end

    def load_stories
      @story_filter ||= StoryFilter.new(get_params, story_scope)
    end

    def build_story
      @story ||= story_scope.new
      @story.attributes = story_params
      @story.save
    end

    def render_story(status = nil)
      status ||= :ok
      render json: @story, status: status, serializer: StorySerializer if @story
    end

    def render_stories
      render json: @story_filter.filtered,
             serializer: StoriesSerializer,
             page: @story_filter.page,
             per_page: @story_filter.per_page
    end

    def render_errors
      render json: @story.errors.messages, status: :bad_request
    end

    def story_params
      permitted_params = post_params.permit(:title, :content, :ministry_id, :image_url, :mcc, :church_id, :training_id,
                                            :location, :language, :privacy, :video_url, :state, :created_by)
      permitted_params[:privacy] = :everyone if permitted_params.key?(:privacy) &&
                                                permitted_params[:privacy] == 'public'
      # Rename and delete uuid params
      { created_by: :person_gr_id, ministry_id: :ministry_gr_id }.each do |k, v|
        permitted_params[v] = permitted_params[k] if permitted_params.key?(k) && Uuid.uuid?(permitted_params[k])
        permitted_params.delete(k)
      end
      permitted_params[:created_by_id] = current_user.id unless permitted_params.key?(:person_gr_id)
      permitted_params[:user_image_url] = permitted_params.delete(:image_url)
      permitted_params
    end

    def request_power
      ministry_id = case params[:action].to_sym
                    when :show, :update
                      Story.find_by(id: params[:id]).try(:ministry).try(:gr_id)
                    else
                      params[:ministry_id]
                    end
      Power.new(current_user, ministry_id)
    end
  end
end
